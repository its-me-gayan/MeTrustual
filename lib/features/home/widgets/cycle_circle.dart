import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CycleCircle extends StatelessWidget {
  final int day;
  final String phase;
  final Color? color;
  final String? label;

  const CycleCircle({
    super.key,
    required this.day,
    required this.phase,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? AppColors.primaryRose;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer dashed ring
          Container(
            width: 186,
            height: 186,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withOpacity(0.2),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
          ),
          // Main Circle
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  accentColor.withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  offset: const Offset(0, 8),
                  blurRadius: 30,
                ),
                BoxShadow(
                  color: accentColor.withOpacity(0.05),
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: GoogleFonts.nunito(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    height: 1,
                  ),
                ),
                Text(
                  label ?? 'Cycle Day',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    phase.toUpperCase(),
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
