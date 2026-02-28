import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/period_journey_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/calendar_day_model.dart';

/// Bottom sheet shown when user taps a calendar day.
/// Shows phase info, logged symptoms, self-care tip, and CTAs.
class DayDetailSheet extends ConsumerWidget {
  final CalendarDayModel day;

  const DayDetailSheet({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Fetch current cycle anchor so we can tell the user which cycle
    //    this day belongs to (current vs previous).
    final periodData = ref.watch(periodHomeDataProvider);
    final currentPeriodStart = periodData?.lastPeriod;

    final phase = _phaseLabel(day);
    final tip = _selfCareTip(day);
    final dateLabel = DateFormat('EEE, MMM d').format(day.date).toUpperCase();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = day.date.isAfter(today);

    // ── Is this day part of the *current* cycle or a previous one? ──────────
    // A day is in the current cycle if it's on/after the most recent period
    // start. Anything before that belongs to a prior cycle.
    final isCurrentCycle = currentPeriodStart == null ||
        !day.date.isBefore(DateTime(currentPeriodStart.year,
            currentPeriodStart.month, currentPeriodStart.day));
    final isPreviousCycle = !isCurrentCycle && !isFuture;

    // ── Has the user actually logged something for this day? ─────────────────
    final hasLog = day.log != null &&
        ((day.log!.flow != null &&
                day.log!.flow!.isNotEmpty &&
                day.log!.flow != 'none') ||
            (day.log!.mood != null && day.log!.mood!.isNotEmpty) ||
            day.log!.symptoms.isNotEmpty ||
            day.log!.hasNote);

    // ── Subtitle line under the phase heading ─────────────────────────────────
    // Examples:
    //   "Current cycle · Day 3 · Logged"       ← today/recent, has log
    //   "Current cycle · Day 3"                 ← today/recent, no log
    //   "Previous cycle · Day 5 · No entry"     ← older, no log
    //   "Previous cycle · Day 5 · Logged"       ← older, has log
    //   "Predicted · Day 27 · AI estimate"      ← future
    final String cycleContextLabel;
    if (isFuture || day.isPredicted) {
      cycleContextLabel = 'Predicted · Day ${day.cycleDay} · AI estimate';
    } else if (isPreviousCycle) {
      cycleContextLabel = hasLog
          ? 'Previous cycle · Day ${day.cycleDay} · Logged'
          : 'Previous cycle · Day ${day.cycleDay} · No entry';
    } else {
      // Current cycle
      cycleContextLabel = hasLog
          ? 'Current cycle · Day ${day.cycleDay} · Logged'
          : 'Current cycle · Day ${day.cycleDay}';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Date ──
          Text(
            dateLabel,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),

          // ── Phase ──
          Text(
            phase,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),

          // ── Cycle context + logged status ──
          Text(
            cycleContextLabel,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isPreviousCycle
                  ? AppColors.textMuted.withOpacity(0.65)
                  : AppColors.textMuted,
            ),
          ),

          // ── Previous-cycle notice ──
          if (isPreviousCycle) ...[
            const SizedBox(height: 10),
            _buildPreviousCycleBanner(),
          ],

          const SizedBox(height: 14),

          // ── Logged symptom chips (only if actually logged) ──
          if (hasLog) _buildLoggedChips(day.log!),

          // ── Predicted label ──
          if (day.isPredicted) _buildPredictedBadge(),

          const SizedBox(height: 12),

          // ── Self-care tip ──
          _buildTipCard(tip, isPreviousCycle),

          const SizedBox(height: 16),

          // ── CTAs ──
          Row(
            children: [
              if (!isFuture) ...[
                Expanded(
                  child: _ActionButton(
                    label: hasLog ? '📝  Edit log' : '📝  Log this day',
                    isPrimary: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      final dateStr = day.date.toIso8601String();
                      context.go('/log?date=$dateStr');
                    },
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _ActionButton(
                  label: '🌿  Rituals',
                  isPrimary: false,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/care');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Luna CTA ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/luna');
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFFE8D0F0), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                backgroundColor: const Color(0xFFFDF0FF),
              ),
              child: Text(
                '🌙  Ask Luna about this phase',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF9060B0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedChips(LogDaySummary log) {
    final chips = <String>[];
    if (log.flow != null && log.flow!.isNotEmpty && log.flow != 'none') {
      chips.add('💧 ${_capitalise(log.flow!)} flow');
    }
    if (log.mood != null && log.mood!.isNotEmpty) {
      chips.add('${log.mood} Mood');
    }
    chips.addAll(log.symptoms.take(3));

    if (chips.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips.map((chip) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F6),
              border: Border.all(color: AppColors.border, width: 1.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              chip,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryRose,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPredictedBadge() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.primaryRose.withOpacity(0.2), width: 1),
        ),
        child: Text(
          '🔮  AI prediction based on your cycle history',
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  /// Banner shown when tapping a day from a *previous* cycle so the user
  /// understands the cycle-day number refers to an older cycle.
  Widget _buildPreviousCycleBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFFD0B8F0).withOpacity(0.5), width: 1),
      ),
      child: Text(
        '📅  This day is from a previous cycle. '
        'Logging it now will help improve future predictions.',
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF8060A0),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildTipCard(String tip, bool isPreviousCycle) {
    // For previous-cycle days with no logged data the self-care tip isn't
    // very relevant — show a more appropriate nudge instead.
    final displayTip = isPreviousCycle
        ? 'Logging past days helps the app learn your unique cycle pattern — '
            'every entry counts 💕'
        : tip;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F5),
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '✨  Self-care:  ',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryRose,
              ),
            ),
            TextSpan(
              text: displayTip,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMid,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  Label helpers
  // ─────────────────────────────────────────────────────

  String _phaseLabel(CalendarDayModel day) {
    if (day.isToday) {
      return switch (day.type) {
        DayType.period => 'Today · Menstrual Phase 🩸',
        DayType.fertile => 'Today · Fertile Window 🌿',
        DayType.fertileHigh => 'Today · Peak Fertile 🎯',
        DayType.follicular => 'Today · Follicular Phase',
        DayType.luteal => 'Today · Luteal Phase',
        _ => 'Today',
      };
    }

    final prefix = day.isPredicted ? 'Predicted: ' : '';
    return switch (day.type) {
      DayType.period =>
        '${prefix}Menstrual · Day ${day.cycleDay} ${_flowEmoji(day.flowIntensity)}',
      DayType.fertile => '${prefix}Fertile Window 🌿',
      DayType.fertileHigh => '${prefix}Peak Fertile Day 🎯',
      DayType.follicular => '${prefix}Follicular Phase',
      DayType.luteal => '${prefix}Luteal Phase',
      _ => '',
    };
  }

  String _selfCareTip(CalendarDayModel day) {
    return switch (day.type) {
      DayType.period => switch (day.cycleDay) {
          1 ||
          2 =>
            'Rest is sacred today 🌸 — gentle heat and iron-rich foods help replenish.',
          3 =>
            'Dark chocolate is your friend 🍫 — magnesium eases cramps naturally.',
          4 ||
          5 =>
            'Gentle yoga or a short walk can relieve bloating and lift your mood.',
          _ => 'Your body is wrapping up — light movement and warm teas help.',
        },
      DayType.follicular =>
        'Energy is rising! Great time to try something new or plan your week.',
      DayType.fertile =>
        'Your body is opening up. Stay hydrated and note any cervical mucus changes.',
      DayType.fertileHigh =>
        'Peak fertility — your best chance to conceive if trying. High energy, embrace it! 🎯',
      DayType.luteal => day.cycleDay > 22
          ? 'Late luteal — PMS may arrive. Magnesium, rest and less caffeine help 💜'
          : 'Progesterone rising — focus on nourishing foods and quality sleep.',
      _ =>
        'Log how you feel today — every entry makes your predictions more accurate 💕',
    };
  }

  String _flowEmoji(FlowIntensity? intensity) {
    return switch (intensity) {
      FlowIntensity.spotting => '🔴',
      FlowIntensity.light => '🟡',
      FlowIntensity.medium => '🟠',
      FlowIntensity.heavy => '🔴',
      null => '',
    };
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────
//  Action button
// ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF09090), Color(0xFFD97B8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRose.withOpacity(0.3),
                offset: const Offset(0, 4),
                blurRadius: 12,
              )
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryRose,
          ),
        ),
      ),
    );
  }
}
