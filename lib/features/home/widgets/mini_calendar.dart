import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class MiniCalendar extends StatelessWidget {
  const MiniCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    final days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'February 2026 🗓️',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: 7 + 35, // Header + 5 weeks
          itemBuilder: (context, index) {
            if (index < 7) {
              return Center(
                child: Text(
                  days[index],
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
              );
            }
            
            final dayNum = index - 12; // Adjust for starting day
            if (dayNum < 1 || dayNum > 28) return const SizedBox();

            bool isPeriod = dayNum >= 2 && dayNum <= 6;
            bool isFertile = (dayNum >= 10 && dayNum <= 15) && dayNum != 14;
            bool isToday = dayNum == 14;

            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday 
                    ? AppColors.primaryRose 
                    : isPeriod 
                        ? AppColors.primaryRose.withOpacity(0.1) 
                        : isFertile 
                            ? AppColors.sageGreen.withOpacity(0.1) 
                            : Colors.transparent,
                boxShadow: isToday ? [
                  BoxShadow(
                    color: AppColors.primaryRose.withOpacity(0.3),
                    offset: const Offset(0, 3),
                    blurRadius: 10,
                  )
                ] : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$dayNum',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isToday 
                      ? Colors.white 
                      : isPeriod 
                          ? AppColors.primaryRose 
                          : isFertile 
                              ? AppColors.sageGreen 
                              : AppColors.textMuted,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
