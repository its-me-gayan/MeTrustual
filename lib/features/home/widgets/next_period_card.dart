import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/home_provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFFFF8F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD1D9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D6D).withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🩸', style: GoogleFonts.nunito(fontSize: 18)),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NEXT PERIOD',
                style: GoogleFonts.nunito(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF758F),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                nextDate,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                daysUntil > 0 ? 'In $daysUntil days' : 'Today!',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6D),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('85%',
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
