import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/cycle_circle.dart';
import '../widgets/mini_calendar.dart';
import '../widgets/next_period_card.dart';
import '../providers/home_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/widgets/app_bottom_nav.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeDataProvider);
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth.currentUser;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Icon(Icons.person_outline, color: AppColors.textMid),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Side-by-side layout for Cycle and Next Period
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildCycleDisplay(homeData),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    flex: 4,
                    child: NextPeriodCard(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildStatsRow(homeData),
              const SizedBox(height: 24),
              const MiniCalendar(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeIndex: 0),
      floatingActionButton: const AppFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
    final avgPeriod = 5; 
    
    return Row(
      children: [
        _buildStatPill('$avgCycle', 'Avg Cycle'),
        const SizedBox(width: 8),
        _buildStatPill('$avgPeriod', 'Period Days', color: const Color(0xFFC9A0D0)),
        const SizedBox(width: 8),
        _buildStatPill('12', 'Logged', color: const Color(0xFF8AB88A)), 
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
}
