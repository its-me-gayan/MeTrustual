import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/premium_gate.dart';
import '../providers/insights_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    final insightsAsync = ref.watch(insightsDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        child: insightsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryRose, strokeWidth: 2)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Could not load insights.\nPlease try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ),
          ),
          data: (data) => _InsightsBody(mode: mode, data: data),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
          activeIndex: _navIndex(GoRouter.of(context)
              .routerDelegate
              .currentConfiguration
              .uri
              .path)),
      floatingActionButton: const AppFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  static int _navIndex(String? route) {
    switch (route) {
      case '/home':
        return 0;
      case '/insights':
        return 1;
      case '/education':
        return 2;
      case '/care':
        return 3;
      default:
        return 1;
    }
  }
}

// ─── Body ───────────────────────────────────────────────────────────────────

class _InsightsBody extends ConsumerWidget {
  final String mode;
  final InsightsData data;

  const _InsightsBody({required this.mode, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = AppColors.getModeColor(mode);

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () async => ref.invalidate(insightsDataProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: AppColors.textDark, size: 20),
                  onPressed: () => context.go('/home'),
                ),
                Text(_title(mode),
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 20),
              child: Text(
                _sub(mode, data),
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),

            // Content
            ...(mode == 'preg'
                ? _pregContent(accentColor)
                : mode == 'ovul'
                    ? _ovulContent(data, accentColor)
                    : _periodContent(data, accentColor)),
          ],
        ),
      ),
    );
  }

  // ── Period Mode ────────────────────────────────────────────────────────────
  List<Widget> _periodContent(InsightsData d, Color accent) {
    final today = DateTime.now();
    return [
      _HeroCard(
          emoji: d.heroEmoji,
          title: d.heroTitle,
          subtitle: d.heroSubtitle,
          accentColor: accent),
      const SizedBox(height: 20),

      // Cycle chart — premium gated
      PremiumGate(
        message: 'Unlock Cycle Analytics',
        child: _InsightCard(
          title:
              '📊 Cycle Length — Last ${d.cycleChart.length > 0 ? d.cycleChart.length : 6} Cycles',
          child: d.cycleChart.isEmpty
              ? _empty('Log more cycles to see your chart')
              : _CycleLengthChart(points: d.cycleChart, color: accent),
        ),
      ),
      const SizedBox(height: 20),

      _InsightCard(
        title: '🌸 Most common symptoms',
        child: d.topSymptoms.isEmpty
            ? _empty('Log symptoms to see patterns')
            : Column(
                children: List.generate(d.topSymptoms.length, (i) {
                  final s = d.topSymptoms[i];
                  return _BarRow(
                      label: s.name,
                      fill: s.ratio,
                      color: symptomColor(i),
                      trailing: '${s.count}×');
                }),
              ),
      ),
      const SizedBox(height: 20),

      _InsightCard(
        title: '🔮 What\'s coming up',
        child: Column(
          children: [
            _UpcomingRow(
              label: '🩸 Next period',
              value: d.nextPeriodDate != null
                  ? '${DateFormat('MMM d').format(d.nextPeriodDate!)} · ${(d.nextPeriodConfidence * 100).round()}%'
                  : 'Log more data',
              color: accent,
            ),
            _UpcomingRow(
              label: '🌿 Fertile window',
              value: (d.fertileWindowStart != null &&
                      d.fertileWindowEnd != null)
                  ? '${DateFormat('MMM d').format(d.fertileWindowStart!)}–${DateFormat('d').format(d.fertileWindowEnd!)}'
                  : 'Calculating...',
              color: AppColors.sageGreen,
            ),
            _UpcomingRow(
              label: '◎ Ovulation',
              value: d.ovulationDate != null
                  ? _ovulLabel(d.ovulationDate!, today)
                  : 'Calculating...',
              color: AppColors.lavender,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      _InsightCard(
        title: '💭 Mood by phase',
        child: Column(
          children: d.moodByPhase
              .map((m) => _BarRow(
                    label: m.phase,
                    fill: m.score,
                    color: _phaseColor(m.phase),
                    trailing: m.emoji,
                  ))
              .toList(),
        ),
      ),
    ];
  }

  // ── Pregnancy Mode ─────────────────────────────────────────────────────────
  List<Widget> _pregContent(Color accent) {
    return [
      _HeroCard(
        emoji: '💙',
        title: 'You\'re doing amazing!',
        subtitle:
            'Keep logging daily to track your wellness journey. Your dedication is beautiful 💕',
        accentColor: accent,
      ),
      const SizedBox(height: 20),
      PremiumGate(
        message: 'Unlock Wellness Analytics',
        child: _InsightCard(
          title: '📊 Activity — Last 7 Days',
          child: _SimpleBarChart(color: accent),
        ),
      ),
    ];
  }

  // ── Ovulation Mode ──────────────────────────────────────────────────────────
  List<Widget> _ovulContent(InsightsData d, Color accent) {
    final today = DateTime.now();
    return [
      _HeroCard(
        emoji: '🎯',
        title: d.cycleChart.length >= 3
            ? 'Your pattern is consistent!'
            : 'Building your fertility profile...',
        subtitle: d.predictionAccuracy > 0
            ? 'Prediction accuracy: ${(d.predictionAccuracy * 100).round()}% — keep logging 🌿'
            : 'Log your cycles to unlock fertility predictions 🌿',
        accentColor: accent,
      ),
      const SizedBox(height: 20),
      PremiumGate(
        message: 'Unlock Fertile Window History',
        child: _InsightCard(
          title:
              '📊 Cycle Length — Last ${d.cycleChart.length > 0 ? d.cycleChart.length : 6} Cycles',
          child: d.cycleChart.isEmpty
              ? _empty('Log more cycles to see your pattern')
              : _CycleLengthChart(points: d.cycleChart, color: accent),
        ),
      ),
      const SizedBox(height: 20),
      _InsightCard(
        title: '🔮 Upcoming predictions',
        child: Column(
          children: [
            _UpcomingRow(
              label: '🌿 Fertile window',
              value: (d.fertileWindowStart != null &&
                      d.fertileWindowEnd != null)
                  ? '${DateFormat('MMM d').format(d.fertileWindowStart!)}–${DateFormat('d').format(d.fertileWindowEnd!)}'
                  : 'Log more data',
              color: accent,
            ),
            _UpcomingRow(
              label: '◎ Ovulation',
              value: d.ovulationDate != null
                  ? _ovulLabel(d.ovulationDate!, today)
                  : 'Calculating...',
              color: AppColors.lavender,
            ),
            _UpcomingRow(
              label: '🩸 Next period',
              value: d.nextPeriodDate != null
                  ? '${DateFormat('MMM d').format(d.nextPeriodDate!)} · ${(d.nextPeriodConfidence * 100).round()}%'
                  : 'Calculating...',
              color: AppColors.primaryRose,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _InsightCard(
        title: '🌸 Most logged symptoms',
        child: d.topSymptoms.isEmpty
            ? _empty('Log symptoms to see patterns')
            : Column(
                children: List.generate(d.topSymptoms.length, (i) {
                  final s = d.topSymptoms[i];
                  return _BarRow(
                      label: s.name,
                      fill: s.ratio,
                      color: accent,
                      trailing: '${s.count}×');
                }),
              ),
      ),
    ];
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static String _ovulLabel(DateTime date, DateTime today) {
    final diff =
        date.difference(DateTime(today.year, today.month, today.day)).inDays;
    final label = DateFormat('MMM d').format(date);
    if (diff == 0) return '$label (today!)';
    if (diff == 1) return '$label (tomorrow)';
    return label;
  }

  static Color _phaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'follicular':
      case 'ovulation':
        return AppColors.sageGreen;
      case 'luteal':
        return AppColors.lavender;
      default:
        return AppColors.primaryRose;
    }
  }

  static Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted)),
      );

  static String _title(String mode) {
    switch (mode) {
      case 'period':
        return 'Your Story ✨';
      case 'preg':
        return 'Your Journey 💙';
      case 'ovul':
        return 'Your Fertility 🌿';
      default:
        return 'Insights';
    }
  }

  static String _sub(String mode, InsightsData d) {
    if (d.cyclesTracked == 0) return 'No cycles logged yet';
    final n = d.cyclesTracked;
    final label = '$n cycle${n == 1 ? '' : 's'}';
    switch (mode) {
      case 'period':
        return '$label of data';
      case 'ovul':
        return '$label tracked';
      default:
        return 'Daily wellness tracking';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color accentColor;

  const _HeroCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accentColor.withOpacity(0.10),
              offset: const Offset(0, 4),
              blurRadius: 14)
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 46)),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  height: 1.5)),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InsightCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 4),
              blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label, trailing;
  final double fill;
  final Color color;

  const _BarRow({
    required this.label,
    required this.fill,
    required this.color,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 82,
              child: Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark))),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fill.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        LinearGradient(colors: [color.withOpacity(0.5), color]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
              width: 38,
              child: Text(trailing,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color))),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  final String label, value;
  final Color color;

  const _UpcomingRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          Text(value,
              style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _CycleLengthChart extends StatelessWidget {
  final List<CycleChartPoint> points;
  final Color color;

  const _CycleLengthChart({required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox();
    final maxLen = points.map((p) => p.length).reduce((a, b) => a > b ? a : b);
    final minLen = points.map((p) => p.length).reduce((a, b) => a < b ? a : b);
    final range = (maxLen - minLen).clamp(1, 100);

    return Column(
      children: [
        SizedBox(
          height: 90,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points.map((p) {
              final norm =
                  0.25 + 0.75 * ((p.length - minLen) / range).clamp(0.0, 1.0);
              final isLast = p == points.last;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${p.length}d',
                          style: GoogleFonts.nunito(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isLast ? color : AppColors.textMuted)),
                      const SizedBox(height: 3),
                      Container(
                        height: 68 * norm,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              color,
                              color.withOpacity(isLast ? 0.85 : 0.55)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: points
              .map((p) => Expanded(
                    child: Text(p.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final Color color;
  const _SimpleBarChart({required this.color});

  @override
  Widget build(BuildContext context) {
    final h = [0.55, 0.72, 0.60, 0.85, 0.68, 0.75, 0.62];
    final l = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      children: [
        SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
                7,
                (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Container(
                          height: 68 * h[i],
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [color, color.withOpacity(0.5)],
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    )),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: l
              .map((x) => Expanded(
                    child: Text(x,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
