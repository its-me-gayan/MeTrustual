import 'package:intl/intl.dart';
import '../../models/calendar_day_model.dart';

/// Pure computation engine. No Flutter/Firestore dependencies.
/// Takes cycle parameters and a map of existing log summaries,
/// and produces a full CalendarDayModel list for a given month.
class CalendarEngine {
  // ── Cycle parameters ──────────────────────────────────
  final DateTime lastPeriodStart; // first day of last known period
  final int cycleLength; // average cycle length in days (default 28)
  final int periodLength; // average period length in days (default 5)
  final DateTime today;

  const CalendarEngine({
    required this.lastPeriodStart,
    this.cycleLength = 28,
    this.periodLength = 5,
    required this.today,
  });

  // ─────────────────────────────────────────────────────
  //  PUBLIC API
  // ─────────────────────────────────────────────────────

  /// Returns a list of [CalendarDayModel] for the given [year] and [month].
  /// [logMap] keys are 'yyyy-MM-dd' strings; values are [LogDaySummary].
  /// The returned list always has padding empty cells so it starts on Sunday.
  List<CalendarDayModel> buildMonth({
    required int year,
    required int month,
    required Map<String, LogDaySummary> logMap,
  }) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startPadding = firstDayOfMonth.weekday % 7; // 0=Sun…6=Sat

    final result = <CalendarDayModel>[];

    // Leading empty cells
    for (int i = 0; i < startPadding; i++) {
      result.add(_emptyCell());
    }

    // Actual days
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      result.add(_classifyDay(date, logMap));
    }

    // Trailing empty cells (complete the last row)
    final totalCells = result.length;
    final remainder = totalCells % 7;
    if (remainder != 0) {
      for (int i = 0; i < (7 - remainder); i++) {
        result.add(_emptyCell());
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────────────
  //  INTERNAL HELPERS
  // ─────────────────────────────────────────────────────

  CalendarDayModel _emptyCell() {
    return CalendarDayModel(
      date: DateTime(0),
      type: DayType.empty,
      isPredicted: false,
      isToday: false,
      cycleDay: 0,
    );
  }

  CalendarDayModel _classifyDay(
      DateTime date, Map<String, LogDaySummary> logMap) {
    final isToday = _isSameDay(date, today);
    final isPast = date.isBefore(today) || isToday;
    final isFuture = date.isAfter(today);

    // Days elapsed since the most recent cycle start that falls before `date`
    final daysSinceStart = _daysSinceCycleStart(date);
    // 0-indexed cycle day within cycle (0 = day 1 of period)
    final cycleDay0 =
        ((daysSinceStart % cycleLength) + cycleLength) % cycleLength;
    final cycleDay = cycleDay0 + 1; // 1-indexed

    // ── Determine phase ──────────────────────────────
    DayType type;
    bool isPredicted;

    // Approximate fertile window: days 9–15 of cycle (ovulation at day 14)
    final fertileStart = 9;
    final fertileEnd = 15;
    final ovulationDay = 14;

    if (cycleDay <= periodLength) {
      // Menstrual
      type = DayType.period;
      isPredicted = isFuture; // past/today = logged, future = predicted
    } else if (cycleDay >= fertileStart && cycleDay <= fertileEnd) {
      // Fertile window
      type = (cycleDay == ovulationDay || cycleDay == ovulationDay - 1)
          ? DayType.fertileHigh
          : DayType.fertile;
      isPredicted = isFuture;
    } else if (cycleDay < fertileStart) {
      // Follicular (between end of period and fertile window)
      type = DayType.follicular;
      isPredicted = isFuture;
    } else {
      // Luteal (after fertile window, before next period)
      type = DayType.luteal;
      isPredicted = isFuture;
    }

    // ── Resolve actual logged flow intensity ──────────
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final log = logMap[dateKey];
    FlowIntensity? flowIntensity;

    if (type == DayType.period) {
      if (log?.flowIntensity != null) {
        // Use actual logged flow
        flowIntensity = log!.flowIntensity;
      } else if (!isFuture) {
        // Past/today with no log — use cycle-day-based default
        flowIntensity = _defaultFlowForDay(cycleDay);
      } else {
        // Future predicted — use cycle-day-based default
        flowIntensity = _defaultFlowForDay(cycleDay);
      }
    }

    return CalendarDayModel(
      date: date,
      type: type,
      isPredicted: isPredicted,
      isToday: isToday,
      cycleDay: cycleDay,
      flowIntensity: flowIntensity,
      log: log,
    );
  }

  /// Days elapsed since the most recent cycle start that falls on or before [date].
  int _daysSinceCycleStart(DateTime date) {
    // Find how many full cycles have passed
    final totalDays = date.difference(lastPeriodStart).inDays;
    return totalDays;
  }

  /// Default flow intensity based on position within period
  FlowIntensity _defaultFlowForDay(int cycleDay) {
    if (cycleDay == 1) return FlowIntensity.light;
    if (cycleDay == 2) return FlowIntensity.medium;
    if (cycleDay == 3) return FlowIntensity.heavy;
    if (cycleDay == 4) return FlowIntensity.medium;
    return FlowIntensity.light; // day 5+
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
