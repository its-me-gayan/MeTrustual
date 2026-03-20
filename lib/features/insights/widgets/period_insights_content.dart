import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_gate.dart';
import '../providers/insights_provider.dart';
import '../widgets/insights_widgets.dart';

class PeriodInsightsContent extends StatelessWidget {
  final InsightsData data;
  final Color accentColor;

  const PeriodInsightsContent({
    required this.data,
    required this.accentColor,
  });

  List<Widget> build(BuildContext context) {
    final today = DateTime.now();
    final hasData = data.nextPeriodDate != null;

    return [
      HeroCard(
          emoji: hasData ? data.heroEmoji : '✨',
          title: hasData ? data.heroTitle : 'Welcome to your story',
          subtitle: hasData
              ? data.heroSubtitle
              : 'Start logging your period to see personalized insights and predictions here.',
          accentColor: accentColor),
      const SizedBox(height: 20),

      // Cycle chart — premium gated
      PremiumGate(
        message: 'Unlock Cycle Analytics',
        child: InsightCard(
          title:
              '📊 Cycle Length — Last ${data.cycleChart.length > 0 ? data.cycleChart.length : 6} Cycles',
          child: data.cycleChart.isEmpty
              ? _empty('Not enough data to show trends yet')
              : CycleLengthChart(points: data.cycleChart, color: accentColor),
        ),
      ),
      const SizedBox(height: 20),

      InsightCard(
        title: '🌸 Most common symptoms',
        child: data.topSymptoms.isEmpty
            ? _empty('Log symptoms to see patterns')
            : Column(
                children: List.generate(data.topSymptoms.length, (i) {
                  final s = data.topSymptoms[i];
                  return BarRow(
                      label: s.name,
                      fill: s.ratio,
                      color: symptomColor(i),
                      trailing: '${s.count}×',
                      icon: s.icon);
                }),
              ),
      ),
      const SizedBox(height: 20),

      InsightCard(
        title: '🔮 What\'s coming up',
        child: Column(
          children: [
            UpcomingRow(
              label: '🩸 Next period',
              value: data.nextPeriodDate != null
                  ? '${DateFormat('MMM d').format(data.nextPeriodDate!)} · ${(data.nextPeriodConfidence * 100).round()}%'
                  : 'Log more data',
              color: accentColor,
            ),
            UpcomingRow(
              label: '🌿 Fertile window',
              value: (data.fertileWindowStart != null &&
                      data.fertileWindowEnd != null)
                  ? '${DateFormat('MMM d').format(data.fertileWindowStart!)}–${DateFormat('d').format(data.fertileWindowEnd!)}'
                  : 'Log more cycles',
              color: AppColors.sageGreen,
            ),
            UpcomingRow(
              label: '◎ Ovulation',
              value: data.ovulationDate != null
                  ? _ovulLabel(data.ovulationDate!, today)
                  : 'Log more cycles',
              color: AppColors.lavender,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      InsightCard(
        title: '💭 Mood by phase',
        child: data.moodByPhase.isEmpty
            ? _empty('Track your mood to see phase trends')
            : Column(
                children: data.moodByPhase
                    .map((m) => BarRow(
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

  String _ovulLabel(DateTime date, DateTime today) {
    final diff = date.difference(today).inDays;
    final formatted = DateFormat('MMM d').format(date);
    if (diff == 0) return '$formatted (today!)';
    if (diff == 1) return '$formatted (tomorrow)';
    return formatted;
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
