import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/calendar_day_model.dart';

/// Single calendar day cell — matches the HTML prototype exactly.
///
/// HTML prototype visual breakdown:
/// ┌─────────────┐
/// │c14  (tiny)  │  ← cycle day badge, top-right, 6px, 40% opacity
/// │             │
/// │   ╔═══╗    │  ← colored bubble: ONLY wraps the day number
/// │   ║ 14║    │    • period logged:    solid rose fill (intensity-based)
/// │   ╚═══╝    │    • period confirmed: rose inner-ring + ✓ badge
/// │            │    • period predicted: ghost fill + dashed border
/// │    · · ·   │  ← symptom dots, 3.5px, below the bubble
/// └─────────────┘
///
/// Key: the background color is on the INNER bubble, not the outer cell.
/// The outer cell is always transparent.
///
/// DaySource visual mapping:
///   logged          → solid rose fill (existing behaviour, unchanged)
///   confirmedJourney→ rose inner ring + small checkmark badge (NEW — fixes
///                     Feb-19 bug where journey anchor had no log entries)
///   predicted       → ghost fill + dashed border (existing behaviour)
class CalendarDayCell extends StatelessWidget {
  final CalendarDayModel day;
  final VoidCallback? onTap;

  const CalendarDayCell({
    super.key,
    required this.day,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (day.type == DayType.empty) return const SizedBox();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Bubble size: ~76% of available width, centered
          final bubbleSize = constraints.maxWidth * 0.76;
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                // ── Cycle day badge row (above bubble) ──
                SizedBox(
                  height: 10,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Text(
                        'c${day.cycleDay}',
                        style: GoogleFonts.nunito(
                          fontSize: 6,
                          fontWeight: FontWeight.w900,
                          color: _cycleTagColor().withOpacity(0.60),
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Colored bubble with day number ──
                _buildBubble(bubbleSize),

                // ── Symptom dots (below bubble) ──
                const SizedBox(height: 2),
                SizedBox(
                  height: 7,
                  child: _buildDots(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBubble(double size) {
    // confirmedJourney uses a Stack to overlay the checkmark badge.
    // All other states use a plain Container (unchanged).
    if (day.type == DayType.period &&
        day.daySource == DaySource.confirmedJourney &&
        !day.isToday) {
      return _buildConfirmedJourneyBubble(size);
    }

    final bg = _bubbleColor();
    final border = _bubbleBorder();
    final textColor = _textColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border,
        boxShadow: day.isToday
            ? [
                BoxShadow(
                  color: AppColors.primaryRose.withOpacity(0.22),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.date.day}',
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: _textWeight(),
          color: textColor,
          height: 1,
        ),
      ),
    );
  }

  /// Confirmed journey bubble: rose inner-ring + small checkmark badge.
  ///
  /// Visual language:
  ///   The ring (not solid fill) signals "we know this happened but you
  ///   didn't tap the log button for it".
  ///   The ✓ badge signals "confirmed from your journey record".
  ///
  /// The badge is intentionally tiny (10×10 px) so it doesn't distract
  /// from the calendar at a glance — it's a secondary detail for users
  /// who notice the difference.
  Widget _buildConfirmedJourneyBubble(double size) {
    final badgeSize = size * 0.28; // ~10px on a 36px bubble
    return SizedBox(
      width: size + badgeSize / 2, // slight extra width for badge overflow
      height: size + badgeSize / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Main bubble: inner ring, no solid fill ──
          Positioned(
            left: 0,
            top: badgeSize / 2,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                // Light rose tint — clearly a period day, but visually
                // distinguished from a solid logged period
                color: _confirmedJourneyFillColor(),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryRose.withOpacity(0.60),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.date.day}',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryRose,
                  height: 1,
                ),
              ),
            ),
          ),

          // ── Checkmark badge — bottom-right corner ──
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: AppColors.primaryRose,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.0),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.check_rounded,
                size: badgeSize * 0.65,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fill color for confirmedJourney bubble.
  /// Scales with flow intensity (same opacity logic as logged, but lighter)
  /// so heavy flow days are still visually heavier than spotting days.
  Color _confirmedJourneyFillColor() {
    switch (day.flowIntensity) {
      case FlowIntensity.spotting:
        return AppColors.primaryRose.withOpacity(0.10);
      case FlowIntensity.light:
        return AppColors.primaryRose.withOpacity(0.14);
      case FlowIntensity.medium:
        return AppColors.primaryRose.withOpacity(0.20);
      case FlowIntensity.heavy:
        return AppColors.primaryRose.withOpacity(0.28);
      case null:
        return AppColors.primaryRose.withOpacity(0.16);
    }
  }

  Widget _buildDots() {
    final dots = <Color>[];

    if (day.log != null) {
      if (day.log!.flow != null && day.log!.flow != 'none') {
        dots.add(AppColors.primaryRose);
      }
      if (day.log!.hasCramps) {
        dots.add(const Color(0xFFE07070));
      }
      if (day.log!.hasFertileSymptom) {
        dots.add(AppColors.sageGreen);
      }
      if (day.log!.hasNote && dots.length < 3) {
        dots.add(AppColors.textMuted);
      }
    }

    if (dots.isEmpty) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: dots.take(3).map((c) {
        return Container(
          width: 3.5,
          height: 3.5,
          margin: const EdgeInsets.symmetric(horizontal: 0.8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // On today's white bubble, use white dots; elsewhere use actual color
            color: day.isToday ? Colors.white.withOpacity(0.8) : c,
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────
  //  Bubble color — only the inner circle, never the full cell
  //  (confirmedJourney handled separately in _buildConfirmedJourneyBubble)
  // ─────────────────────────────────────────────────────

  Color _bubbleColor() {
    // Today: white bubble with rose border ring
    if (day.isToday) return Colors.white;

    switch (day.type) {
      case DayType.period:
        return _periodBubbleColor();
      case DayType.fertile:
        return day.isPredicted
            ? AppColors.sageGreen.withOpacity(0.12)
            : AppColors.sageGreen.withOpacity(0.25);
      case DayType.fertileHigh:
        return day.isPredicted
            ? AppColors.sageGreen.withOpacity(0.16)
            : AppColors.sageGreen.withOpacity(0.38);
      case DayType.follicular:
      case DayType.luteal:
      case DayType.empty:
        return Colors.transparent;
    }
  }

  Color _periodBubbleColor() {
    if (day.isPredicted) {
      // Predicted: clearly visible ghost on the app's pink #FDF4F6 background.
      // 0.08 was too faint — bumped to 0.20 so the predicted period days
      // are legible without looking confirmed. The dashed border adds shape.
      return AppColors.primaryRose.withOpacity(0.20);
    }
    // confirmedJourney is handled in _buildConfirmedJourneyBubble —
    // this path is only reached for logged (DaySource.logged) period days.
    switch (day.flowIntensity) {
      case FlowIntensity.spotting:
        return AppColors.primaryRose.withOpacity(0.18);
      case FlowIntensity.light:
        return AppColors.primaryRose.withOpacity(0.28);
      case FlowIntensity.medium:
        return AppColors.primaryRose.withOpacity(0.48);
      case FlowIntensity.heavy:
        // Heavy = solid rose, white text
        return AppColors.primaryRose.withOpacity(0.72);
      case null:
        return AppColors.primaryRose.withOpacity(0.22);
    }
  }

  BoxBorder? _bubbleBorder() {
    if (day.isToday) {
      return Border.all(
        color: AppColors.primaryRose,
        width: 2.0,
      );
    }
    // Predicted days get a thin dashed-style border
    if (day.isPredicted) {
      switch (day.type) {
        case DayType.period:
          // Stronger border so ghost-pink period days show against pink bg
          return Border.all(
            color: AppColors.primaryRose.withOpacity(0.55),
            width: 1.4,
          );
        case DayType.fertile:
        case DayType.fertileHigh:
          return Border.all(
            color: AppColors.sageGreen.withOpacity(0.45),
            width: 1.2,
          );
        default:
          return null;
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────
  //  Text color
  // ─────────────────────────────────────────────────────

  Color _textColor() {
    if (day.isToday) return AppColors.primaryRose;

    switch (day.type) {
      case DayType.period:
        if (!day.isPredicted &&
            day.flowIntensity == FlowIntensity.heavy &&
            day.daySource == DaySource.logged) {
          return Colors.white;
        }
        return day.isPredicted
            ? AppColors.primaryRose.withOpacity(0.75)
            : AppColors.primaryRose;
      case DayType.fertile:
      case DayType.fertileHigh:
        return day.isPredicted
            ? AppColors.sageGreen.withOpacity(0.65)
            : const Color(0xFF3A8A5A);
      case DayType.follicular:
      case DayType.luteal:
        return AppColors.textDark.withOpacity(0.55);
      case DayType.empty:
        return Colors.transparent;
    }
  }

  FontWeight _textWeight() {
    if (day.isToday) return FontWeight.w900;
    if (day.type == DayType.period && !day.isPredicted) return FontWeight.w900;
    if (day.type == DayType.fertileHigh && !day.isPredicted)
      return FontWeight.w800;
    return FontWeight.w700;
  }

  // Cycle tag color matches text color at reduced opacity
  Color _cycleTagColor() => _textColor();
}
