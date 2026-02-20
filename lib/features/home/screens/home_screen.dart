import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/cycle_circle.dart';
import '../widgets/mini_calendar.dart';
import '../widgets/next_period_card.dart';
import '../providers/home_provider.dart';
import '../../../models/user_profile_model.dart';
import '../../../core/providers/firebase_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeDataProvider);
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good morning ☀️',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '${user?.displayName ?? 'Aisha'} 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCycleDisplay(homeData),
                  const SizedBox(height: 24),
                  _buildStatsRow(homeData),
                  const SizedBox(height: 24),
                  const MiniCalendar(),
                  const SizedBox(height: 24),
                  const NextPeriodCard(),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNav(context, 0),
            ),
            Positioned(
              bottom: 44,
              left: MediaQuery.of(context).size.width / 2 - 26,
              child: _buildFAB(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleDisplay(Map<String, dynamic>? homeData) {
    if (homeData == null) {
      return const CycleCircle(day: 0, phase: 'No data yet 🌸');
    }
    
    final lastCycle = homeData['lastCycle'];
    final phase = homeData['phase'] as String;
    final cycleDay = DateTime.now().difference(lastCycle.startDate).inDays + 1;

    return CycleCircle(day: cycleDay, phase: phase);
  }

  Widget _buildStatsRow(Map<String, dynamic>? homeData) {
    final avgCycle = homeData?['prediction']?.averageLength ?? 28;
    final avgPeriod = 5; // This could also be calculated from history
    
    return Row(
      children: [
        _buildStatPill('$avgCycle', 'Avg Cycle'),
        const SizedBox(width: 8),
        _buildStatPill('$avgPeriod', 'Period Days', color: const Color(0xFFC9A0D0)),
        const SizedBox(width: 8),
        _buildStatPill('12', 'Logged', color: const Color(0xFF8AB88A)), // Example logged count
      ],
    );
  }

  Widget _buildStatPill(String value, String label, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color ?? AppColors.primaryRose,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int activeIndex) {
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
          _buildNavItem(context, '🌸', 'Log', activeIndex == 1, '/log'),
          const SizedBox(width: 52), // Space for FAB
          _buildNavItem(context, '✨', 'Insights', activeIndex == 2, '/insights'),
          _buildNavItem(context, '📖', 'Learn', activeIndex == 3, '/education'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String icon, String label, bool isActive, String route) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: TextStyle(
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

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/log'),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRose.withOpacity(0.45),
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
