import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/insights_provider.dart';

// ─── Hero Card ───────────────────────────────────────────────────────────────

class HeroCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color accentColor;

  const HeroCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

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

// ─── Insight Card ───────────────────────────────────────────────────────────

class InsightCard extends StatelessWidget {
  final String title;
  final Widget child;

  const InsightCard({required this.title, required this.child});

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

// ─── Bar Row ────────────────────────────────────────────────────────────────

class BarRow extends StatelessWidget {
  final String label;
  final double fill;
  final Color color;
  final String trailing;
  final String? icon;

  const BarRow({
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
          SizedBox(
              width: 80,
              child: Text(icon != null ? '$icon $label' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark))),
          const SizedBox(width: 8),
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

// ─── Upcoming Row ────────────────────────────────────────────────────────────

class UpcomingRow extends StatelessWidget {
  final String label, value;
  final Color color;

  const UpcomingRow({
    required this.label,
    required this.value,
    required this.color,
  });

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

// ─── Cycle Length Chart ──────────────────────────────────────────────────────

class CycleLengthChart extends StatelessWidget {
  final List<CycleChartPoint> points;
  final Color color;

  const CycleLengthChart({required this.points, required this.color});

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
                        color: color.withOpacity(i == points.length - 1 ? 1 : 0.3),
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

// ─── Simple Bar Chart ────────────────────────────────────────────────────────

class SimpleBarChart extends StatelessWidget {
  final Color color;
  const SimpleBarChart({required this.color});

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

// ─── Symptom Color Helper ────────────────────────────────────────────────────

Color symptomColor(int index) {
  const colors = [
    Color(0xFFD97B8A), // rose
    Color(0xFFA880C8), // lavender
    Color(0xFF6A9E7A), // sage
    Color(0xFF5A80C0), // blue
    Color(0xFFD4936A), // amber
  ];
  return colors[index % colors.length];
}
