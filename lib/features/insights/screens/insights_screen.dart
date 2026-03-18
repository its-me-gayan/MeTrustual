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
    final hasData = d.nextPeriodDate != null;

    return [
      _HeroCard(
          emoji: hasData ? d.heroEmoji : '✨',
          title: hasData ? d.heroTitle : 'Welcome to your story',
          subtitle: hasData
              ? d.heroSubtitle
              : 'Start logging your period to see personalized insights and predictions here.',
          accentColor: accent),
      const SizedBox(height: 20),

      // Cycle chart — premium gated
      PremiumGate(
        message: 'Unlock Cycle Analytics',
        child: _InsightCard(
          title:
              '📊 Cycle Length — Last ${d.cycleChart.length > 0 ? d.cycleChart.length : 6} Cycles',
          child: d.cycleChart.isEmpty
              ? _empty('Not enough data to show trends yet')
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
                      trailing: '${s.count}×',
                      icon: s.icon);
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
                  : 'Log more cycles',
              color: AppColors.sageGreen,
            ),
            _UpcomingRow(
              label: '◎ Ovulation',
              value: d.ovulationDate != null
                  ? _ovulLabel(d.ovulationDate!, today)
                  : 'Log more cycles',
              color: AppColors.lavender,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      _InsightCard(
        title: '💭 Mood by phase',
        child: d.moodByPhase.isEmpty
            ? _empty('Track your mood to see phase trends')
            : Column(
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
    final hasData = d.cycleChart.isNotEmpty;

    return [
      _HeroCard(
        emoji: hasData ? '🎯' : '✨',
        title: hasData
            ? (d.cycleChart.length >= 3
                ? 'Your pattern is consistent!'
                : 'Building your fertility profile...')
            : 'Welcome to your journey',
        subtitle: hasData
            ? (d.predictionAccuracy > 0
                ? 'Prediction accuracy: ${(d.predictionAccuracy * 100).round()}% — keep logging 🌿'
                : 'Log your cycles to unlock fertility predictions 🌿')
            : 'Log your cycles to see personalized fertility insights and predictions.',
        accentColor: accent,
      ),
      const SizedBox(height: 20),
      PremiumGate(
        message: 'Unlock Fertile Window History',
        child: _InsightCard(
          title:
              '📊 Cycle Length — Last ${d.cycleChart.length > 0 ? d.cycleChart.length : 6} Cycles',
          child: d.cycleChart.isEmpty
              ? _empty('Not enough data to show trends yet')
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
                  : 'Log more cycles',
              color: AppColors.lavender,
            ),
            _UpcomingRow(
              label: '🩸 Next period',
              value: d.nextPeriodDate != null
                  ? '${DateFormat('MMM d').format(d.nextPeriodDate!)} · ${(d.nextPeriodConfidence * 100).round()}%'
                  : 'Log more cycles',
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
                      color: symptomColor(i),
                      trailing: '${s.count}×',
                      icon: s.icon);
                }),
              ),
      ),
    ];
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _title(String mode) {
    if (mode == 'preg') return 'Your Journey 💙';
    if (mode == 'ovul') return 'Your Fertility 🌿';
    return 'Your Story ✨';
  }

  String _sub(String mode, InsightsData d) {
    if (mode == 'preg') return 'Week 24 of 40';
    if (mode == 'ovul') return '${d.cycleChart.length} cycles tracked';
    return '${d.cycleChart.length} months of data';
  }

  String _ovulLabel(DateTime date, DateTime today) {
    final diff = date.difference(today).inDays;
    final formatted = DateFormat('MMM d').format(date);
    if (diff == 0) return '$formatted (today!)';
    if (diff == 1) return '$formatted (tomorrow)';
    return formatted;
  }

  Color symptomColor(int i) {
    const colors = [
      AppColors.primaryRose,
      Color(0xFFA880C8),
      Color(0xFF6A9E7A),
      Color(0xFF5A80C0)
    ];
    return colors[i % colors.length];
  }

  Color _phaseColor(String phase) {
    if (phase.toLowerCase().contains('menst')) return AppColors.primaryRose;
    if (phase.toLowerCase().contains('foll')) return const Color(0xFF6A9E7A);
    if (phase.toLowerCase().contains('ovul')) return const Color(0xFF6A9E7A);
    return const Color(0xFFA880C8);
  }

  Widget _empty(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.analytics_outlined,
                color: AppColors.textMuted.withOpacity(0.3), size: 32),
            const SizedBox(height: 8),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Components ────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color accentColor;

  const _HeroCard(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark.withOpacity(0.7),
                  height: 1.4)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double fill;
  final Color color;
  final String trailing;
  final String? icon; // emoji icon from Firestore config (optional)

  const _BarRow({
    required this.label,
    required this.fill,
    required this.color,
    required this.trailing,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Icon bubble (shown only for symptom rows that have a config icon)
          if (icon != null && icon != '•') ...[
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(icon!, style: const TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 74,
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
            ),
          ] else ...[
            SizedBox(
              width: 80,
              child: Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
            ),
          ],
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fill.clamp(0.05, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [color.withOpacity(0.6), color]),
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(trailing,
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── FIX: Wrapped value Text in Flexible so it wraps instead of overflowing.
//        Label is given a fixed width; value right-aligns within remaining space.
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed-width label so it never bleeds into the value side
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
          ),
          // Value wraps freely in whatever space is left
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color),
            ),
          ),
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
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(points.length, (i) {
              final val = points[i].length;
              final h = (val / 40 * 100).clamp(10.0, 100.0);
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${val}d',
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: h,
                    decoration: BoxDecoration(
                        color:
                            color.withOpacity(i == points.length - 1 ? 1 : 0.3),
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Oldest',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
            Text('Latest',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
          ],
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
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final h = [40, 60, 30, 80, 50, 70, 45][i];
          return Container(
            width: 30,
            height: h.toDouble(),
            decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6)),
          );
        }),
      ),
    );
  }
}
