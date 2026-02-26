import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/utils/calendar_engine.dart';
import '../../../models/calendar_day_model.dart';
import '../../../core/providers/period_journey_provider.dart';

// ─────────────────────────────────────────────────────────────
//  Calendar month offset state (0 = current month)
// ─────────────────────────────────────────────────────────────
final calendarMonthOffsetProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────
//  Derived: which year+month the calendar is showing
// ─────────────────────────────────────────────────────────────
final calendarDisplayMonthProvider = Provider<DateTime>((ref) {
  final offset = ref.watch(calendarMonthOffsetProvider);
  final now = DateTime.now();
  // Add offset months to today
  return DateTime(now.year, now.month + offset, 1);
});

// ─────────────────────────────────────────────────────────────
//  Stream log summaries for a given mode + month from Firestore
// ─────────────────────────────────────────────────────────────
final _calendarLogMapProvider =
    StreamProvider.family<Map<String, LogDaySummary>, _MonthKey>(
        (ref, key) async* {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final uid = auth.currentUser?.uid;

  if (uid == null) {
    yield {};
    return;
  }

  // Build date range for the month
  final firstDay = DateTime(key.year, key.month, 1);
  final lastDay = DateTime(key.year, key.month + 1, 0);
  final startKey = DateFormat('yyyy-MM-dd').format(firstDay);
  final endKey = DateFormat('yyyy-MM-dd').format(lastDay);

  yield* firestore
      .collection('users')
      .doc(uid)
      .collection('logs')
      .doc(key.mode)
      .collection('entries')
      .where('date', isGreaterThanOrEqualTo: startKey)
      .where('date', isLessThanOrEqualTo: endKey)
      .snapshots()
      .map((snap) {
    final map = <String, LogDaySummary>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      map[doc.id] = LogDaySummary(
        flow: d['flow'] as String?,
        mood: d['mood'] as String?,
        symptoms: List<String>.from(d['symptoms'] as List? ?? []),
        hasNote: (d['note'] as String? ?? '').isNotEmpty,
      );
    }
    return map;
  });
});

// ─────────────────────────────────────────────────────────────
//  Main calendar provider — combines cycle predictions + logs
// ─────────────────────────────────────────────────────────────
final calendarDaysProvider =
    Provider<AsyncValue<List<CalendarDayModel>>>((ref) {
  final displayMonth = ref.watch(calendarDisplayMonthProvider);
  final mode = ref.watch(modeProvider);

  // ✅ Use periodHomeDataProvider — same SmartCycleDetector-derived source
  //    as the home screen, so calendar always matches home screen cycle day.
  final periodData = ref.watch(periodHomeDataProvider);

  final monthKey = _MonthKey(
    year: displayMonth.year,
    month: displayMonth.month,
    mode: mode,
  );

  final logMapAsync = ref.watch(_calendarLogMapProvider(monthKey));

  return logMapAsync.when(
    data: (logMap) {
      DateTime lastPeriodStart;
      int cycleLength;
      int periodLength;

      if (periodData != null && periodData.lastPeriod != null) {
        // ✅ Anchor from SmartCycleDetector — always up to date with logs
        lastPeriodStart = periodData.lastPeriod!;
        cycleLength = periodData.cycleLen;
        periodLength = periodData.periodLen;
      } else {
        // Fallback — no cycle data yet, use a sane default
        final now = DateTime.now();
        lastPeriodStart = DateTime(now.year, now.month, 1);
        cycleLength = 28;
        periodLength = 5;
      }

      final engine = CalendarEngine(
        lastPeriodStart: lastPeriodStart,
        cycleLength: cycleLength,
        periodLength: periodLength,
        today: DateTime.now(),
      );

      final days = engine.buildMonth(
        year: displayMonth.year,
        month: displayMonth.month,
        logMap: logMap,
      );

      return AsyncValue.data(days);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// ─────────────────────────────────────────────────────────────
//  Helper key for the family provider
// ─────────────────────────────────────────────────────────────
class _MonthKey {
  final int year;
  final int month;
  final String mode;

  const _MonthKey({
    required this.year,
    required this.month,
    required this.mode,
  });

  @override
  bool operator ==(Object other) =>
      other is _MonthKey &&
      other.year == year &&
      other.month == month &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(year, month, mode);
}
