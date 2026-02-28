import 'package:intl/intl.dart';
import '../../models/calendar_day_model.dart';

/// Pure computation engine — no Flutter/Firestore dependencies.
///
/// ═══ PAST DAYS — three rules, in priority order ══════════════════════
///
///  1. LOGGED flow (hasLoggedFlow)
///     → DayType.period, DaySource.logged, flowIntensity from log
///
///  2. CONFIRMED JOURNEY ANCHOR (daysSinceAnchor in [0, periodLength))
///     → DayType.period, DaySource.confirmedJourney
///     → flowIntensity from confirmedFlow param (real Firebase value)
///     → Renders as inner-ring + checkmark badge (see CalendarDayCell)
///     → Fixes the Feb-19 bug: lastPeriod stored in journey/period but
///       user never logged daily entries for those days
///
///  3. PHASE COLOUR from cycle math (fallthrough)
///     → DaySource.predicted (legacy, unchanged behaviour)
///     → If math says DayType.period but no log/anchor → DayType.follicular
///       (we cannot confirm period without evidence)
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

  /// The confirmed flow intensity from journey/period.flow in Firebase.
  /// Used when rendering confirmedJourney days (no daily log entry exists).
  /// Example: 'heavy' → FlowIntensity.heavy on Feb 19–22 cells.
  /// Null = fall back to FlowIntensity.medium.
  final String? confirmedFlow;

  const CalendarEngine({
    required this.lastPeriodStart,
    this.cycleLength = 28,
    this.periodLength = 5,
    required this.today,
    this.nextPeriodOverride,
    this.confirmedFlow, // NEW — pass periodData.flow from the provider
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
      // ── Rule 1: User logged flow → solid period bubble ─────────────────
      if (hasLoggedFlow) {
        return CalendarDayModel(
          date: date,
          type: DayType.period,
          isPredicted: false,
          isToday: isToday,
          cycleDay: cycleDay,
          flowIntensity: log!.flowIntensity,
          log: log,
          daySource: DaySource.logged, // user-logged: solid fill
        );
      }

      // ── Rule 2: Confirmed journey anchor window ─────────────────────────
      //
      // lastPeriodStart is the CONFIRMED period start from Firebase
      // journey/period.lastPeriod. If this date falls within
      // [lastPeriodStart, lastPeriodStart + periodLength), show it as period
      // even though no daily log entry exists.
      //
      // This fixes the core bug: user sets lastPeriod=Feb 19 during
      // onboarding (or CycleAnchorSync writes it), but never taps the log
      // button for Feb 19-22 individually. Previously these showed as
      // follicular (white). Now they show with the confirmedJourney style:
      // rose inner-ring + checkmark badge.
      //
      // We use the ACTUAL flow from journey/period.flow (confirmedFlow param)
      // so the intensity is clinically accurate, not a hardcoded guess.
      //
      // Guard: only apply to the CURRENT anchor window, not past cycles.
      // The modulo _cycleDay() naturally handles multi-cycle history.
      // We check direct day difference (not modulo) so only days within
      // the exact [lastPeriodStart, lastPeriodStart+periodLength) window
      // of the most recent confirmed period are affected.
      final daysSinceAnchor = date.difference(lastPeriodStart).inDays;
      if (daysSinceAnchor >= 0 && daysSinceAnchor < periodLength) {
        return CalendarDayModel(
          date: date,
          type: DayType.period,
          isPredicted: false,
          isToday: isToday,
          cycleDay: cycleDay,
          // Use real flow from Firebase (journey/period.flow), not a hardcode.
          // Falls back to medium if journey never stored a flow value.
          flowIntensity: _flowFromString(confirmedFlow) ?? FlowIntensity.medium,
          log: log,
          daySource: DaySource.confirmedJourney, // ring + checkmark badge
        );
      }

      // ── Rule 3: Phase colour from cycle math (unchanged fallthrough) ────
      //
      // IMPORTANT: if math says DayType.period (cycle days 1–periodLen)
      // but there is no log AND this isn't the current confirmed anchor,
      // show as follicular instead — we cannot confirm period without
      // a log entry or confirmed anchor.
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
        daySource: DaySource.predicted, // legacy non-logged past day
      );
    }

    // ──────────────────────────────────────────────────────────────────────
    //  FUTURE (unchanged logic — only daySource added)
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

      // Use override-based cycle day (cd) so the calendar label resets to
      // c1 at the predicted period start, not the old anchor's count.
      return CalendarDayModel(
        date: date,
        type: type,
        isPredicted: true,
        isToday: false,
        cycleDay: cd, // override-relative: c1 at predicted period start
        flowIntensity: flowIntensity,
        log: log,
        daySource: DaySource.predicted,
      );
    } else if (override != null) {
      // ── Case B: between today and AI-predicted period ─────────────────────
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
      daySource: DaySource.predicted,
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

  /// Converts Firebase flow string → FlowIntensity.
  /// Returns null if the string is unrecognised or null.
  FlowIntensity? _flowFromString(String? flow) {
    switch (flow?.toLowerCase()) {
      case 'heavy':
        return FlowIntensity.heavy;
      case 'medium':
        return FlowIntensity.medium;
      case 'light':
        return FlowIntensity.light;
      case 'spotting':
        return FlowIntensity.spotting;
      default:
        return null;
    }
  }

  CalendarDayModel _emptyCell() => CalendarDayModel(
        date: DateTime(0),
        type: DayType.empty,
        isPredicted: false,
        isToday: false,
        cycleDay: 0,
        daySource: DaySource.predicted,
      );

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
