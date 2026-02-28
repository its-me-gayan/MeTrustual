/// Represents the classification and data for a single calendar day.
/// This is a pure in-memory model — not stored in Firestore directly.
/// It is derived from combining cycle prediction data + any existing log entry.
class CalendarDayModel {
  final DateTime date;

  // ── Cycle classification ──────────────────────────────
  final DayType type; // period / fertile / luteal / follicular
  final bool isPredicted; // true = future AI prediction, false = logged/past
  final bool isToday;
  final int cycleDay; // 1-indexed cycle day number (e.g. c1, c14)

  // ── Period intensity (only relevant when type == period) ──
  final FlowIntensity? flowIntensity; // null if not a period day or unpredicted

  // ── Logged data for this day (null if no log exists) ──
  final LogDaySummary? log;

  // ── Data source — drives visual treatment in CalendarDayCell ──────────────
  // logged           = user tapped the log screen for this day (solid fill)
  // confirmedJourney = from journey/period.lastPeriod — no daily log entry
  //                    (inner ring + checkmark badge instead of solid fill)
  // predicted        = future AI/math estimate (ghost fill + dashed border)
  final DaySource daySource;

  const CalendarDayModel({
    required this.date,
    required this.type,
    required this.isPredicted,
    required this.isToday,
    required this.cycleDay,
    this.flowIntensity,
    this.log,
    this.daySource = DaySource.predicted, // safe default
  });
}

/// Where the cycle data for this day came from.
/// Drives visual differentiation in CalendarDayCell so the user can always
/// tell whether a period marker came from their own log entry or from the
/// confirmed journey anchor (onboarding / CycleAnchorSync).
enum DaySource {
  /// User explicitly logged flow for this day via the log screen.
  /// Visual: solid rose fill, no badge.
  logged,

  /// Period confirmed from journey/period.lastPeriod in Firebase,
  /// but NO daily log entry exists for this specific day.
  /// Common when: user set last period during onboarding, or
  /// CycleAnchorSyncNotifier wrote a new anchor but not all days in the
  /// period window were individually logged.
  /// Visual: rose inner-ring + small checkmark badge.
  confirmedJourney,

  /// Future AI/math prediction — not yet confirmed.
  /// Visual: ghost fill + dashed border.
  predicted,
}

/// What phase this day falls in
enum DayType {
  period, // menstrual
  fertile, // fertile window (non-peak)
  fertileHigh, // peak fertile / ovulation
  follicular, // post-period, pre-fertile
  luteal, // post-ovulation
  empty, // padding cell (before/after month)
}

/// Flow intensity — drives colour shade on the calendar
enum FlowIntensity {
  spotting, // p1 — barely-there pink
  light, // p2 — soft rose
  medium, // p3 — mid rose
  heavy, // p4 — deep rose
}

/// Compact summary of a log entry, just enough for the calendar to show dots
class LogDaySummary {
  final String? flow; // 'heavy' | 'medium' | 'light' | 'none'
  final String? mood;
  final List<String> symptoms;
  final bool hasNote;

  const LogDaySummary({
    this.flow,
    this.mood,
    required this.symptoms,
    required this.hasNote,
  });

  bool get hasCramps => symptoms.any((s) => s.toLowerCase().contains('cramp'));

  bool get hasFertileSymptom => symptoms.any((s) =>
      s.toLowerCase().contains('fertile') ||
      s.toLowerCase().contains('libido') ||
      s.toLowerCase().contains('ovulation'));

  /// Convert Firestore flow string → FlowIntensity
  FlowIntensity? get flowIntensity {
    switch (flow) {
      case 'heavy':
        return FlowIntensity.heavy;
      case 'medium':
        return FlowIntensity.medium;
      case 'light':
        return FlowIntensity.light;
      case 'none':
        return null;
      default:
        return null;
    }
  }
}
