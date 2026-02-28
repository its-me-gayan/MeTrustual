import 'package:intl/intl.dart';
import '../../models/calendar_day_model.dart';

/// Pure computation engine — no Flutter/Firestore dependencies.
///
/// ═══ PAST DAYS — two rules, strictly separated ═══════════════════════
///
///  PERIOD colour (pink) ← ONLY if the user actually logged flow
///  PHASE colour (green/follicular/luteal) ← ALWAYS from cycle math
///
///  Why separate? Because:
///   • Period pink without a log = false data (Feb 19-22 bug)
///   • Phase colours without a log = medically correct context
///     (green fertile window on old months is valid even if nothing logged)
///
/// ═══ FUTURE DAYS ═════════════════════════════════════════════════════
///
///  nextPeriodOverride (AI predicted next period, stored as
///  aiPrediction.nextPeriod in Firebase — NEVER as lastPeriod):
///   • dates ≥ override → use override as next cycle anchor
///   • dates < override → fertile window back-calculated from override
///     (ovulation = override − 14 days) so calendar matches prediction card
///
/// ═══ TWO PERIODS IN ONE MONTH ════════════════════════════════════════
///
///  Handled automatically by modulo arithmetic.
///  26-day cycle, anchor = Jan 3 → Jan 29 = cycle day 1 → another period.
///  The same formula works for any cycle length.
///
/// ═══ FIREBASE KEY CLARIFICATION ══════════════════════════════════════
///
///  lastPeriodStart (passed here) = CONFIRMED period only.
///  nextPeriodOverride (passed here) = AI prediction only.
///  They are NEVER swapped or merged — kept fully separate.
///
class CalendarEngine {
  final DateTime lastPeriodStart;
  final int cycleLength;
  final int periodLength;
  final DateTime today;

  /// AI-predicted next period.
  /// Stored in Firebase as `aiPrediction.nextPeriod` — NEVER as `lastPeriod`.
  final DateTime? nextPeriodOverride;

  const CalendarEngine({
    required this.lastPeriodStart,
    this.cycleLength = 28,
    this.periodLength = 5,
    required this.today,
    this.nextPeriodOverride,
  });

  // ─────────────────────────────────────────────────────
  //  PUBLIC API
  // ─────────────────────────────────────────────────────

  List<CalendarDayModel> buildMonth({
    required int year,
    required int month,
    required Map<String, LogDaySummary> logMap,
  }) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startPadding = firstDay.weekday % 7;

    final result = <CalendarDayModel>[];
    for (var i = 0; i < startPadding; i++) result.add(_emptyCell());
    for (var d = 1; d <= daysInMonth; d++) {
      result.add(_classifyDay(DateTime(year, month, d), logMap));
    }
    final rem = result.length % 7;
    if (rem != 0) {
      for (var i = 0; i < 7 - rem; i++) result.add(_emptyCell());
    }
    return result;
  }

  // ─────────────────────────────────────────────────────
  //  CLASSIFICATION LOGIC
  // ─────────────────────────────────────────────────────

  CalendarDayModel _classifyDay(
      DateTime date, Map<String, LogDaySummary> logMap) {
    final isToday = _same(date, today);
    final isFuture = date.isAfter(today);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final log = logMap[dateKey];
    final hasLoggedFlow =
        log?.flow != null && log!.flow != 'none' && log.flow!.isNotEmpty;
    final cycleDay = _cycleDay(date);

    // ──────────────────────────────────────────────────────────────────────
    //  PAST & TODAY
    // ──────────────────────────────────────────────────────────────────────
    if (!isFuture) {
      // Rule 1: Period pink — ONLY for days with actual logged flow.
      //         This prevents false pink on Feb 19-22 when user never logged.
      if (hasLoggedFlow) {
        return CalendarDayModel(
          date: date,
          type: DayType.period,
          isPredicted: false,
          isToday: isToday,
          cycleDay: cycleDay,
          flowIntensity: log!.flowIntensity,
          log: log,
        );
      }

      // Rule 2: Phase colour (fertile/follicular/luteal) — from cycle math.
      //         Always show so navigating to old months shows meaningful context.
      //         IMPORTANT: if math says DayType.period (cycle days 1–periodLen)
      //         but there is no log, show as follicular instead — we cannot
      //         confirm period without a log entry.
      final mathPhase = _phaseForCycleDay(cycleDay);
      final displayType =
          mathPhase == DayType.period ? DayType.follicular : mathPhase;

      return CalendarDayModel(
        date: date,
        type: displayType,
        isPredicted: false,
        isToday: isToday,
        cycleDay: cycleDay,
        log: log,
      );
    }

    // ──────────────────────────────────────────────────────────────────────
    //  FUTURE
    // ──────────────────────────────────────────────────────────────────────
    DayType type;
    FlowIntensity? flowIntensity;
    final override = nextPeriodOverride;

    if (override != null && !date.isBefore(override)) {
      // ── Case A: on or after AI-predicted next period ─────────────────────
      final day0 =
          (date.difference(override).inDays % cycleLength + cycleLength) %
              cycleLength;
      final cd = day0 + 1;
      type = _phaseForCycleDay(cd);
      if (type == DayType.period) flowIntensity = _defaultFlow(cd);

      return CalendarDayModel(
        date: date,
        type: type,
        isPredicted: true,
        isToday: false,
        cycleDay: cd,
        flowIntensity: flowIntensity,
        log: log,
      );
    } else if (override != null) {
      // ── Case B: between today and AI-predicted period ─────────────────────
      // Back-calculate fertile window from override → matches prediction card.
      final ovulation = override.subtract(const Duration(days: 14));
      final fertileFrom = ovulation.subtract(const Duration(days: 5));
      final fertileTo = ovulation.add(const Duration(days: 1));

      if (!date.isBefore(fertileFrom) && !date.isAfter(fertileTo)) {
        type = (_same(date, ovulation) ||
                _same(date, ovulation.subtract(const Duration(days: 1))))
            ? DayType.fertileHigh
            : DayType.fertile;
      } else if (date.isBefore(fertileFrom)) {
        type = DayType.follicular;
      } else {
        type = DayType.luteal;
      }
    } else {
      // ── Case C: no override — pure cycle math ─────────────────────────────
      type = _phaseForCycleDay(cycleDay);
      if (type == DayType.period) flowIntensity = _defaultFlow(cycleDay);
    }

    return CalendarDayModel(
      date: date,
      type: type,
      isPredicted: true,
      isToday: false,
      cycleDay: cycleDay,
      flowIntensity: flowIntensity,
      log: log,
    );
  }

  // ─────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────

  /// 1-indexed cycle day via modulo from lastPeriodStart.
  /// Handles past (negative) and future (large positive) offsets.
  /// Also handles TWO PERIODS IN ONE MONTH automatically:
  ///   anchor=Jan 3, cycleLen=26 → Jan 29 = day 1 (second period that month).
  int _cycleDay(DateTime date) {
    final total = date.difference(lastPeriodStart).inDays;
    final day0 = ((total % cycleLength) + cycleLength) % cycleLength;
    return day0 + 1;
  }

  /// Phase from 1-indexed cycle day.
  DayType _phaseForCycleDay(int cycleDay) {
    const fertileStart = 9;
    const fertileEnd = 15;
    const ovulationDay = 14;
    if (cycleDay <= periodLength) return DayType.period;
    if (cycleDay >= fertileStart && cycleDay <= fertileEnd) {
      return (cycleDay == ovulationDay || cycleDay == ovulationDay - 1)
          ? DayType.fertileHigh
          : DayType.fertile;
    }
    return cycleDay < fertileStart ? DayType.follicular : DayType.luteal;
  }

  FlowIntensity _defaultFlow(int cycleDay) {
    if (cycleDay == 1) return FlowIntensity.light;
    if (cycleDay == 2) return FlowIntensity.medium;
    if (cycleDay == 3) return FlowIntensity.heavy;
    if (cycleDay == 4) return FlowIntensity.medium;
    return FlowIntensity.light;
  }

  CalendarDayModel _emptyCell() => CalendarDayModel(
        date: DateTime(0),
        type: DayType.empty,
        isPredicted: false,
        isToday: false,
        cycleDay: 0,
      );

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
