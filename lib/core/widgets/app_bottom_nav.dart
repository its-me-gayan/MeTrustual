import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../providers/mode_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBottomNav extends StatelessWidget {
  final int activeIndex;
  const AppBottomNav({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(44)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, '🏠', 'Home', activeIndex == 0, '/home'),
          _buildNavItem(
              context, '✨', 'Insights', activeIndex == 1, '/insights'),
          const SizedBox(width: 52),
          _buildNavItem(context, '📖', 'Learn', activeIndex == 2, '/education'),
          _buildNavItem(context, '🌿', 'Care', activeIndex == 3, '/care'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String icon, String label,
      bool isActive, String route) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.nunito(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isActive ? AppColors.primaryRose : const Color(0xFFE0B0B0),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class AppFAB extends ConsumerWidget {
  const AppFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(modeProvider);

    final Color fabColor = switch (currentMode) {
      'preg' => const Color(0xFF4A70B0),
      'ovul' => const Color(0xFF5A8E6A),
      _ => AppColors.primaryRose,
    };

    return GestureDetector(
      onTap: () => context.go('/log'),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: currentMode == 'period' ? AppColors.primaryGradient : null,
          color: currentMode == 'period' ? null : fabColor,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: fabColor.withOpacity(0.45),
              offset: const Offset(0, 6),
              blurRadius: 20,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
