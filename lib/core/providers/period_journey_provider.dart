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

  final anchor =
      SmartCycleDetector.mostRecentPeriodStart(detected) ?? journeyLastPeriod;

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
