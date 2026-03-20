import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_gate.dart';
import '../providers/insights_provider.dart';
import '../widgets/insights_widgets.dart';

class OvulationInsightsContent extends StatelessWidget {
  final InsightsData data;
  final Color accentColor;

  const OvulationInsightsContent({
    required this.data,
    required this.accentColor,
  });

  List<Widget> build(BuildContext context) {
    return [
      HeroCard(
          emoji: '🎯',
          title: 'Peak Fertility',
          subtitle: 'Today is your most fertile day. Log BBT to confirm ovulation.',
          accentColor: accentColor),
      const SizedBox(height: 20),

      PremiumGate(
        message: 'Unlock Fertility Trends',
        child: InsightCard(
          title: '🌡️ Basal Body Temperature',
          child: SimpleBarChart(color: accentColor),
        ),
      ),
      const SizedBox(height: 20),

      InsightCard(
        title: '🧪 LH Test Results',
        child: Column(
          children: [
            BarRow(label: 'Today', fill: 0.9, color: accentColor, trailing: 'Peak'),
            BarRow(label: 'Yesterday', fill: 0.5, color: accentColor.withOpacity(0.7), trailing: 'High'),
          ],
        ),
      ),
      const SizedBox(height: 20),

      InsightCard(
        title: '💧 Cervical Mucus',
        child: Column(
          children: [
            BarRow(label: 'Today', fill: 0.8, color: const Color(0xFF5A80C0), trailing: 'Egg White'),
            BarRow(label: 'Yesterday', fill: 0.4, color: const Color(0xFF5A80C0).withOpacity(0.7), trailing: 'Creamy'),
          ],
        ),
      ),
    ];
  }
}
