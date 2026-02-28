import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/prediction_engine.dart';
import '../utils/smart_cycle_detector.dart';
import '../utils/smart_prediction_engine.dart';
import '../../../core/services/ai_prediction_service.dart';

export '../utils/smart_prediction_engine.dart'
    show PredictionSource, SmartPredictionResult;
export '../../../core/services/ai_prediction_service.dart'
    show AiPredictionResult;

// ─────────────────────────────────────────────────────────────────────────────
// Raw stream: users/{uid}/journey/period
// ─────────────────────────────────────────────────────────────────────────────
final periodJourneyProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(uid)
      .collection('journey')
      .doc('period')
      .snapshots()
      .map((s) => s.exists ? s.data() : null);
});

// ─────────────────────────────────────────────────────────────────────────────
// Raw stream: all daily period logs {dateKey → data}
// ─────────────────────────────────────────────────────────────────────────────
final periodLogsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value({});
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(uid)
      .collection('logs')
      .doc('period')
      .collection('entries')
      .orderBy('date')
      .snapshots()
      .map((snap) => {for (final doc in snap.docs) doc.id: doc.data()});
});

// ─────────────────────────────────────────────────────────────────────────────
// PeriodHomeData — everything the home screen needs, with source metadata
// ─────────────────────────────────────────────────────────────────────────────
class PeriodHomeData {
  final DateTime? lastPeriod;
  final int cycleLen;
  final int periodLen;
  final String? flow;
  final List<String> symptoms;
  final int cycleDay;
  final String phaseLabel;
  final CyclePhase phase;
  final DateTime? nextPeriod;
  final double confidence;
  final PredictionSource source;
  final int detectedCycles;
  final String sourceLabel;

  /// Non-null when the AI has made a prediction this session
  final AiPredictionResult? aiResult;

  /// True while AI call is in flight
  final bool aiLoading;

  const PeriodHomeData({
    required this.lastPeriod,
    required this.cycleLen,
    required this.periodLen,
    required this.flow,
    required this.symptoms,
    required this.cycleDay,
    required this.phaseLabel,
    required this.phase,
    required this.nextPeriod,
    required this.confidence,
    required this.source,
    required this.detectedCycles,
    required this.sourceLabel,
    this.aiResult,
    this.aiLoading = false,
  });

  // Is AI driving predictions (vs pure math)?
  bool get isAiDriven => aiResult != null;

  // Progress 0→1 toward 3 confirmed cycles (for the learning bar)
  double get learningProgress {
    if (source == PredictionSource.confident) return 1.0;
    return (detectedCycles / 3).clamp(0.0, 1.0);
  }

  // NEW: Used by HomeScreen banner
  bool get isFullyLearned => learningProgress >= 1.0;

  int get cyclesToConfidence => (3 - detectedCycles).clamp(0, 3);
}

// ─────────────────────────────────────────────────────────────────────────────
// AI trigger provider — AsyncNotifier that runs the AI call when logs change
// Stores the result so the UI can rebuild when it arrives
// ─────────────────────────────────────────────────────────────────────────────
class _AiNotifier extends AutoDisposeAsyncNotifier<AiPredictionResult?> {
  @override
  Future<AiPredictionResult?> build() async {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return null;

    final firestore = ref.watch(firestoreProvider);
    final logsAsync = ref.watch(periodLogsProvider);
    final journeyAsync = ref.watch(periodJourneyProvider);

    final logs = logsAsync.valueOrNull ?? {};
    final journey = journeyAsync.valueOrNull;
    if (journey == null) return null;

    DateTime? journeyLastPeriod;
    final rawLP = journey['lastPeriod'];
    if (rawLP is Timestamp) {
      journeyLastPeriod = rawLP.toDate();
    } else if (rawLP is String) {
      journeyLastPeriod = DateTime.tryParse(rawLP);
    }

    final journeyCycleLen = (journey['cycleLen'] as num?)?.toInt() ?? 28;
    final journeyPeriodLen = (journey['periodLen'] as num?)?.toInt() ?? 5;

    final detected = SmartCycleDetector.detect(logs);

    if (detected.where((c) => c.cycleLength != null).length < kAiMinCycles) {
      return null;
    }

    final service = AiPredictionService(firestore: firestore, uid: uid);
    return service.getPrediction(
      detectedCycles: detected,
      journeyCycleLen: journeyCycleLen,
      journeyPeriodLen: journeyPeriodLen,
      journeyLastPeriod: journeyLastPeriod,
    );
  }
}

final _aiPredictionProvider =
    AsyncNotifierProvider.autoDispose<_AiNotifier, AiPredictionResult?>(
  _AiNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Main combined provider — merges journey + logs + AI result
// ─────────────────────────────────────────────────────────────────────────────
final periodHomeDataProvider = Provider.autoDispose<PeriodHomeData?>((ref) {
  final journeyAsync = ref.watch(periodJourneyProvider);
  final logsAsync = ref.watch(periodLogsProvider);
  final aiAsync = ref.watch(_aiPredictionProvider);

  if (journeyAsync.isLoading) return null;
  final journey = journeyAsync.valueOrNull;
  if (journey == null) return null;

  final logs = logsAsync.valueOrNull ?? {};

  DateTime? journeyLastPeriod;
  final rawLP = journey['lastPeriod'];
  if (rawLP is Timestamp) {
    journeyLastPeriod = rawLP.toDate();
  } else if (rawLP is String) {
    journeyLastPeriod = DateTime.tryParse(rawLP);
  }

  final journeyCycleLen = (journey['cycleLen'] as num?)?.toInt() ?? 28;
  final journeyPeriodLen = (journey['periodLen'] as num?)?.toInt() ?? 5;
  final flow = journey['flow'] as String?;
  final symptoms = List<String>.from(journey['symptoms'] ?? []);

  final detected = SmartCycleDetector.detect(logs);

  final aiResult = aiAsync.valueOrNull;
  final aiLoading = aiAsync.isLoading;

  final int cycleLen;
  final int periodLen;
  final DateTime? nextPeriod;
  final double confidence;
  final PredictionSource source;
  final String sourceLabel;

  if (aiResult != null) {
    cycleLen = aiResult.cycleLength;
    periodLen = aiResult.periodLength;
    nextPeriod = aiResult.nextPeriod;
    confidence = aiResult.confidencePct / 100.0;
    source = detected.where((c) => c.cycleLength != null).length >= 3
        ? PredictionSource.confident
        : PredictionSource.building;
    sourceLabel =
        'AI · ${detected.where((c) => c.cycleLength != null).length} logged cycles · '
        '${aiResult.confidencePct}% confidence';
  } else {
    final math = SmartPredictionEngine.predict(
      detectedCycles: detected,
      journeyCycleLen: journeyCycleLen,
      journeyPeriodLen: journeyPeriodLen,
      journeyLastPeriod: journeyLastPeriod,
    );
    cycleLen = math.cycleLength;
    periodLen = math.periodLength;
    nextPeriod = math.nextPeriod;
    confidence = math.confidence;
    source = math.source;
    sourceLabel =
        aiLoading ? '✨ AI is analysing your cycles…' : math.sourceLabel;
  }

  // ── Resolve the best "last period start" anchor ──────────────────────────
  // SmartCycleDetector scans daily logs and returns the most recent run of
  // flow entries. However it can be fooled: if the user only logged flow on
  // e.g. Feb 25-26 but their REAL period started Feb 19 (stored in Firebase),
  // the detector declares Feb 25 as a *new* period — wrongly overriding Feb 19.
  //
  // Rule: if the detected start falls within half a cycle of journeyLastPeriod,
  // they are the SAME period. Trust the earlier, user-confirmed journeyLastPeriod.
  // Only accept the detected start as a genuinely new period if it is at least
  // (cycleLen / 2) days after journeyLastPeriod.
  final _detectedStart = SmartCycleDetector.mostRecentPeriodStart(detected);
  final DateTime? anchor;
  if (_detectedStart != null && journeyLastPeriod != null) {
    final gapDays = _detectedStart.difference(journeyLastPeriod).inDays;
    if (gapDays >= (cycleLen / 2).round()) {
      // Detected start is far enough ahead → genuinely a newer cycle
      anchor = _detectedStart;
    } else {
      // Detected start is within the same cycle window as journeyLastPeriod
      // (user only logged mid/late period days) → trust Firebase's value
      anchor = journeyLastPeriod;
    }
  } else {
    anchor = _detectedStart ?? journeyLastPeriod;
  }

  if (anchor == null) {
    return PeriodHomeData(
      lastPeriod: null,
      cycleLen: cycleLen,
      periodLen: periodLen,
      flow: flow,
      symptoms: symptoms,
      cycleDay: 0,
      phaseLabel: 'Set your last period 🌸',
      phase: CyclePhase.menstruation,
      nextPeriod: null,
      confidence: confidence,
      source: source,
      detectedCycles: detected.length,
      sourceLabel: sourceLabel,
      aiResult: aiResult,
      aiLoading: aiLoading,
    );
  }

  final cycleDay = DateTime.now().difference(anchor).inDays + 1;
  final phase = PredictionEngine.getCurrentPhase(
    lastPeriodStart: anchor,
    averageCycleLength: cycleLen,
    averagePeriodLength: periodLen,
  );

  return PeriodHomeData(
    lastPeriod: anchor,
    cycleLen: cycleLen,
    periodLen: periodLen,
    flow: flow,
    symptoms: symptoms,
    cycleDay: cycleDay.clamp(1, cycleLen),
    phaseLabel: _phaseLabel(phase, cycleDay),
    phase: phase,
    nextPeriod: nextPeriod,
    confidence: confidence,
    source: source,
    detectedCycles: detected.length,
    sourceLabel: sourceLabel,
    aiResult: aiResult,
    aiLoading: aiLoading,
  );
});

String _phaseLabel(CyclePhase phase, int day) {
  switch (phase) {
    case CyclePhase.menstruation:
      return 'Period · Day $day 🩸';
    case CyclePhase.follicular:
      return 'Follicular Phase 🌱';
    case CyclePhase.ovulation:
      return 'Ovulation Window 🌸';
    case CyclePhase.luteal:
      return 'Luteal Phase 🌙';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CycleAnchorSyncNotifier
// ─────────────────────────────────────────────────────────────────────────────
//
// FIREBASE DATA MODEL — two separate keys, never conflated:
//
//   users/{uid}/journey/period {
//     lastPeriod:    Timestamp   ← CONFIRMED actual period start ONLY
//                                  (set during onboarding or written here
//                                   when a genuine new period is detected
//                                   from daily logs)
//                                  ⚠️  NEVER overwritten with AI predictions
//
//     cycleLen:      int         ← best known average, updated from logs
//     periodLen:     int         ← best known average, updated from logs
//
//     aiPrediction: {            ← AI prediction — SEPARATE key
//       nextPeriod:   Timestamp  ← predicted, not confirmed
//       cycleLength:  int
//       periodLength: int
//       confidencePct: int
//       insight:      String
//       generatedAt:  Timestamp
//     }
//   }
//
// This notifier watches daily logs + journey doc.
// When it detects that:
//   (a) lastPeriod is null (user skipped during onboarding), OR
//   (b) a genuinely NEW period has been logged (gap ≥ cycleLen/2 from stored
//       lastPeriod — same half-cycle proximity rule as the anchor resolver)
//
// ...it writes ONLY to lastPeriod / cycleLen / periodLen.
// It NEVER touches aiPrediction.nextPeriod.
//
// HOW TO USE — watch in HomeScreen build():
//   ref.watch(cycleAnchorSyncProvider);
// ─────────────────────────────────────────────────────────────────────────────

class _SyncResult {
  final DateTime? writtenAnchor;
  final bool didWrite;
  const _SyncResult({this.writtenAnchor, this.didWrite = false});
}

class CycleAnchorSyncNotifier extends AutoDisposeAsyncNotifier<_SyncResult> {
  @override
  Future<_SyncResult> build() async {
    final auth = ref.watch(firebaseAuthProvider);
    final firestore = ref.watch(firestoreProvider);
    final uid = auth.currentUser?.uid;
    if (uid == null) return const _SyncResult();

    final journeyAsync = ref.watch(periodJourneyProvider);
    final logsAsync = ref.watch(periodLogsProvider);

    final journey = journeyAsync.valueOrNull;
    final logs = logsAsync.valueOrNull ?? {};

    // ── Parse stored CONFIRMED lastPeriod ────────────────────────────────────
    DateTime? journeyLastPeriod;
    final rawLP = journey?['lastPeriod'];
    if (rawLP is Timestamp) {
      journeyLastPeriod = rawLP.toDate();
    } else if (rawLP is String) {
      journeyLastPeriod = DateTime.tryParse(rawLP);
    }
    final journeyCycleLen = (journey?['cycleLen'] as num?)?.toInt() ?? 28;

    // ── Detect actual period starts from logs ────────────────────────────────
    final detected = SmartCycleDetector.detect(logs);
    final detectedStart = SmartCycleDetector.mostRecentPeriodStart(detected);

    if (detectedStart == null) return const _SyncResult(); // no logs yet

    // ── Decide if this is a genuinely NEW period or same cycle ───────────────
    //
    // Half-cycle proximity rule:
    //   gap < cycleLen/2  → user only logged mid/late days of the CURRENT
    //                       period (e.g. logged Feb 25-26 but period started
    //                       Feb 19) → keep Firebase as-is
    //   gap ≥ cycleLen/2  → detected start is far enough ahead to be a
    //                       NEW actual period → update Firebase
    //   lastPeriod null   → first time, always write
    //
    final bool shouldWrite;
    if (journeyLastPeriod == null) {
      // No stored period at all (user skipped onboarding step)
      shouldWrite = true;
    } else {
      final gapDays = detectedStart.difference(journeyLastPeriod).inDays;
      final halfCycle = (journeyCycleLen / 2).round();
      shouldWrite = gapDays >= halfCycle;
    }

    if (!shouldWrite) return const _SyncResult();

    // ── Compute best cycle/period length estimates from real log data ─────────
    final completeCycles =
        detected.where((c) => c.cycleLength != null).toList();
    final avgCycleLen = completeCycles.isNotEmpty
        ? (completeCycles.map((c) => c.cycleLength!).reduce((a, b) => a + b) /
                completeCycles.length)
            .round()
        : journeyCycleLen;

    final detectedPeriodLen = SmartCycleDetector.averagePeriodLength(detected);
    final journeyPeriodLen = (journey?['periodLen'] as num?)?.toInt() ?? 5;
    final bestPeriodLen = detectedPeriodLen != null && detected.length >= 2
        ? detectedPeriodLen.round()
        : journeyPeriodLen;

    // ── Write ONLY confirmed period fields — never aiPrediction ──────────────
    try {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('journey')
          .doc('period')
          .set({
        'lastPeriod': Timestamp.fromDate(detectedStart), // confirmed actual
        'cycleLen': avgCycleLen,
        'periodLen': bestPeriodLen,
        // aiPrediction is intentionally NOT touched here
      }, SetOptions(merge: true));

      debugPrint('[CycleAnchorSync] Wrote confirmed lastPeriod='
          '${detectedStart.toIso8601String().substring(0, 10)} '
          'cycleLen=$avgCycleLen periodLen=$bestPeriodLen');

      return _SyncResult(writtenAnchor: detectedStart, didWrite: true);
    } catch (e) {
      debugPrint('[CycleAnchorSync] Write failed: $e');
      return const _SyncResult();
    }
  }
}

final cycleAnchorSyncProvider =
    AsyncNotifierProvider.autoDispose<CycleAnchorSyncNotifier, _SyncResult>(
  CycleAnchorSyncNotifier.new,
);
