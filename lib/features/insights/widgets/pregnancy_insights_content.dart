import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_gate.dart';
import '../providers/insights_provider.dart';
import '../widgets/insights_widgets.dart';

class PregnancyInsightsContent extends StatelessWidget {
  final InsightsData data;
  final Color accentColor;

  const PregnancyInsightsContent({
    required this.data,
    required this.accentColor,
  });

  List<Widget> build(BuildContext context) {
    return [
      HeroCard(
          emoji: '👶',
          title: 'Baby is growing!',
          subtitle: 'Week 24: Your baby is about the size of a papaya. Their hearing is well-developed now.',
          accentColor: accentColor),
      const SizedBox(height: 20),
      
      PremiumGate(
        message: 'Unlock Pregnancy Milestones',
        child: InsightCard(
          title: '📈 Weight Gain Tracker',
          child: SimpleBarChart(color: accentColor),
        ),
      ),
      const SizedBox(height: 20),

      InsightCard(
        title: '🦶 Kick Counter',
        child: Column(
          children: [
            BarRow(label: 'Today', fill: 0.8, color: accentColor, trailing: '12 kicks'),
            BarRow(label: 'Yesterday', fill: 0.6, color: accentColor.withOpacity(0.7), trailing: '10 kicks'),
          ],
        ),
      ),
      const SizedBox(height: 20),

      InsightCard(
        title: '🤰 Body Changes',
        child: Column(
          children: [
            BarRow(label: 'Energy', fill: 0.4, color: const Color(0xFFD4936A), trailing: 'Low'),
            BarRow(label: 'Sleep', fill: 0.5, color: const Color(0xFF5A80C0), trailing: 'Fair'),
          ],
        ),
      ),
    ];
  }
}
