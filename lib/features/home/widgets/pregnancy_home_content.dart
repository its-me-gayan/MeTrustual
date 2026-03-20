import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_gate.dart';
import '../widgets/cycle_circle.dart';

class PregnancyHomeContent extends StatelessWidget {
  final int logsCount;

  const PregnancyHomeContent({required this.logsCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(
          child: CycleCircle(
              day: 24,
              phase: '2nd Trimester 💙',
              color: Color(0xFF4A70B0),
              label: 'Weeks'),
        ),
        const SizedBox(height: 16),
        _buildPillsRow(
          {
            'value': '113',
            'label': 'Days to Go',
            'color': const Color(0xFF4A70B0)
          },
          {
            'value': 'Jun 5',
            'label': 'Due Date',
            'color': const Color(0xFF9870C0)
          },
          third: {
            'value': logsCount.toString(),
            'label': 'Logs',
            'color': const Color(0xFF8AB88A)
          },
        ),
        const SizedBox(height: 24),
        PremiumGate(
            message: 'Unlock Weekly Baby Updates', child: _buildBabyCard()),
        const SizedBox(height: 24),
        _buildNextBanner(
          title: 'Next Appointment',
          value: 'Mar 3 🩺',
          sub: '28-week glucose screen',
          color: const Color(0xFF4A70B0),
          icon: '🗓️',
        ),
      ],
    );
  }

  Widget _buildBabyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF4A70B0).withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 16)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('👶 Baby Updates',
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          Text('Week 24: Baby is about the size of a papaya!',
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMid)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A70B0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Baby weight: ~600g • Length: ~30cm',
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4A70B0))),
          ),
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
