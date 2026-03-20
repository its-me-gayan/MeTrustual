import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_gate.dart';
import '../widgets/cycle_circle.dart';

class OvulationHomeContent extends StatelessWidget {
  final int logsCount;
  final Map<String, dynamic>? homeData;

  const OvulationHomeContent({
    required this.logsCount,
    required this.homeData,
  });

  @override
  Widget build(BuildContext context) {
    final avgCycleOvul = homeData?['prediction']?.averageLength ?? 28;

    return Column(
      children: [
        const Center(
          child: CycleCircle(
              day: 14,
              phase: '🎯 Peak Fertile',
              color: Color(0xFF5A8E6A),
              label: 'Cycle Day'),
        ),
        const SizedBox(height: 16),
        _buildPillsRow(
          {
            'value': 'Today',
            'label': 'Ovulation',
            'color': const Color(0xFF5A8E6A)
          },
          {
            'value': 'Mar 6',
            'label': 'Next Period',
            'color': AppColors.primaryRose
          },
          third: {
            'value': avgCycleOvul.toString(),
            'label': 'Cycle Len',
            'color': const Color(0xFF8AB88A)
          },
        ),
        const SizedBox(height: 24),
        PremiumGate(
            message: 'Unlock Fertile Window Analysis',
            child: _buildFertileBar()),
        const SizedBox(height: 24),
        _buildNextBanner(
          title: 'Ovulation Prediction',
          value: 'Today, Feb 21 🎯',
          sub: '89% confidence · Log BBT to confirm',
          color: const Color(0xFF5A8E6A),
          percentage: 89,
        ),
      ],
    );
  }

  Widget _buildFertileBar() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🌱 Fertile Window',
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.5,
              minHeight: 8,
              backgroundColor: const Color(0xFF5A8E6A).withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF5A8E6A)),
            ),
          ),
          const SizedBox(height: 8),
          Text('Peak fertility: Today & Tomorrow',
              style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildNextBanner({
    required String title,
    required String value,
    required String sub,
    required Color color,
    String? icon,
    int? percentage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.5)),
              if (icon != null)
                Text(icon, style: const TextStyle(fontSize: 16)),
              if (percentage != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$percentage%',
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: color)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(sub,
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMid)),
        ],
      ),
    );
  }

  Widget _buildPillsRow(Map<String, dynamic> pill1, Map<String, dynamic> pill2,
      {Map<String, dynamic>? third}) {
    return Row(
      children: [
        _buildStatPill(pill1['value'], pill1['label'], color: pill1['color']),
        const SizedBox(width: 8),
        _buildStatPill(pill2['value'], pill2['label'], color: pill2['color']),
        if (third != null) ...[
          const SizedBox(width: 8),
          _buildStatPill(third['value'], third['label'], color: third['color']),
        ],
      ],
    );
  }

  Widget _buildStatPill(String value, String label, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color ?? AppColors.primaryRose)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}
