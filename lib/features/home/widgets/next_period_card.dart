import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/home_provider.dart';

class NextPeriodCard extends ConsumerWidget {
  const NextPeriodCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeDataProvider);
    final prediction = homeData?['prediction'];

    // ✅ fixed: cast prediction to Map to access keys safely
    final predictionMap = prediction as Map<String, dynamic>?;

    final nextDate = predictionMap != null
        ? DateFormat('MMMM d')
            .format(DateTime.parse(predictionMap['nextPeriodDate']))
        : '---';

    final daysUntil = predictionMap != null
        ? DateTime.parse(predictionMap['nextPeriodDate'])
            .difference(DateTime.now())
            .inDays
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F2), Color(0xFFFCE8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCD0D8), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NEXT PERIOD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$nextDate 🩸',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                daysUntil > 0 ? 'In $daysUntil days' : 'Today!',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: 0.85,
                  strokeWidth: 5,
                  backgroundColor: AppColors.border,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryRose),
                  strokeCap: StrokeCap.round,
                ),
              ),
              const Text(
                '85%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryRose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
