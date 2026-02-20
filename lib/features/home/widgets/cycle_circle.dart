import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CycleCircle extends StatelessWidget {
  final int day;
  final String phase;

  const CycleCircle({
    super.key,
    required this.day,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer dashed ring (simulated with a container and border)
          Container(
            width: 186,
            height: 186,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryRose.withOpacity(0.2),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(93),
            ),
          ),
          // Main Circle
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.cycleCircleGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRose.withOpacity(0.2),
                  offset: const Offset(0, 8),
                  blurRadius: 30,
                ),
                BoxShadow(
                  color: const Color(0xFFFCE8E8).withOpacity(0.5),
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryRose,
                    height: 1,
                  ),
                ),
                const Text(
                  'Cycle Day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRose,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    phase,
                    style: const TextStyle(
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
