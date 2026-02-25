/// Analyses daily log entries to detect actual period start dates and
/// compute real cycle lengths — without any user input needed.
///
/// The journey answers (lastPeriod, cycleLen) are just an initial seed.
/// This service builds the ground-truth picture from what the user actually
/// logged day-by-day.
library;

class DetectedCycle {
  /// Day the period actually started (flow went from none → non-none)
  final DateTime startDate;

  /// How many days of flow were logged (period length)
  final int periodDays;

  /// Cycle length in days (null for the most recent cycle — it hasn't ended)
  final int? cycleLength;

  const DetectedCycle({
    required this.startDate,
    required this.periodDays,
    this.cycleLength,
  });
}

class SmartCycleDetector {
  /// Flow values that count as "bleeding" (period is active)
  static const _activeFlow = {'heavy', 'medium', 'light', 'spotting'};

  /// Minimum consecutive bleeding days to count as a real period
  /// (filters out random spotting from being mistaken for a period start)
  static const _minPeriodDays = 2;

  /// Maximum gap (days) between bleeding entries that still counts as one
  /// continuous period (e.g. light day, skip a day, light day = same period)
  static const _maxGapWithinPeriod = 1;

  // ─────────────────────────────────────────────────────────────────────────
  // Main entry point
  // ─────────────────────────────────────────────────────────────────────────

  /// Takes a flat map of {dateString → logData} from Firestore (or
  /// SharedPreferences) and returns detected cycles sorted oldest → newest.
  ///
  /// [logs] keys must be 'yyyy-MM-dd' strings.
  static List<DetectedCycle> detect(Map<String, dynamic> logs) {
    if (logs.isEmpty) return [];

    // ── 1. Build sorted list of (date, flow) ──────────────────────────────
    final entries = logs.entries
        .where((e) => e.value is Map)
        .map((e) {
          final date = DateTime.tryParse(e.key);
          final flow = (e.value as Map)['flow'] as String? ?? 'none';
          return date != null ? (date: date, flow: flow) : null;
        })
        .whereType<({DateTime date, String flow})>()
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (entries.isEmpty) return [];

    // ── 2. Group consecutive bleeding days into "runs" ────────────────────
    final List<List<DateTime>> runs = [];
    List<DateTime>? currentRun;

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isActive = _activeFlow.contains(entry.flow.toLowerCase());

      if (!isActive) {
        if (currentRun != null && currentRun.length >= _minPeriodDays) {
          runs.add(currentRun);
        }
        currentRun = null;
        continue;
      }

      if (currentRun == null) {
        currentRun = [entry.date];
      } else {
        final gap = entry.date.difference(currentRun.last).inDays;
        if (gap <= _maxGapWithinPeriod + 1) {
          currentRun.add(entry.date);
        } else {
          // Gap too large — close the current run, start a new one
          if (currentRun.length >= _minPeriodDays) runs.add(currentRun);
          currentRun = [entry.date];
        }
      }
    }
    // Don't forget the last open run
    if (currentRun != null && currentRun.length >= _minPeriodDays) {
      runs.add(currentRun);
    }

    if (runs.isEmpty) return [];

    // ── 3. Convert runs to DetectedCycle objects ──────────────────────────
    final cycles = <DetectedCycle>[];
    for (int i = 0; i < runs.length; i++) {
      final run = runs[i];
      final start = run.first;
      final periodDays = run.last.difference(run.first).inDays + 1;

      int? cycleLength;
      if (i + 1 < runs.length) {
        // Cycle length = days from this period start to the next period start
        cycleLength = runs[i + 1].first.difference(start).inDays;
        // Sanity check: ignore physiologically impossible cycle lengths
        if (cycleLength < 18 || cycleLength > 60) cycleLength = null;
      }

      cycles.add(DetectedCycle(
        startDate: start,
        periodDays: periodDays,
        cycleLength: cycleLength,
      ));
    }

    return cycles;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper: most recent period start from detected cycles
  // Returns null if no cycles have been detected yet
  // ─────────────────────────────────────────────────────────────────────────
  static DateTime? mostRecentPeriodStart(List<DetectedCycle> cycles) {
    if (cycles.isEmpty) return null;
    return cycles.last.startDate;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper: average period length from detected cycles
  // ─────────────────────────────────────────────────────────────────────────
  static double? averagePeriodLength(List<DetectedCycle> cycles) {
    if (cycles.isEmpty) return null;
    final sum = cycles.map((c) => c.periodDays).reduce((a, b) => a + b);
    return sum / cycles.length;
  }
}
