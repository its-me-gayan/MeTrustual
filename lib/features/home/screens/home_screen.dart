import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/mode_provider.dart';
import '../widgets/cycle_circle.dart';
import '../widgets/mini_calendar.dart';
import '../widgets/next_period_card.dart';
import '../providers/home_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/widgets/app_bottom_nav.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final homeData = ref.watch(homeDataProvider);
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth.currentUser;
    final currentMode = ref.watch(modeProvider);

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
                      child: const Icon(Icons.person_outline,
                          color: AppColors.textMid),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildModeSpecificContent(currentMode, homeData),
              const SizedBox(height: 30),
              _buildSwitchModeCard(currentMode),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          AppBottomNav(activeIndex: _getNavIndex(_currentRoute)),
      floatingActionButton: const AppFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  String get _currentRoute {
    final String? location =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    return location ?? '/home';
  }

  int _getNavIndex(String route) {
    switch (route) {
      case '/home':
        return 0;
      case '/log':
        return 1;
      case '/insights':
        return 2;
      case '/learn':
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildModeSpecificContent(
      String currentMode, Map<String, dynamic>? homeData) {
    switch (currentMode) {
      case 'period':
        final lastCycle = homeData?['lastCycle'];
        final phase = homeData?['phase'] as String? ?? 'No data yet 🌸';
        final cycleDay = lastCycle != null
            ? DateTime.now().difference(lastCycle.startDate).inDays + 1
            : 0;
        final avgCycle = homeData?['prediction']?.averageLength ?? 28;
        const avgPeriod = 5;

        return Column(
          children: [
            Center(
              child: CycleCircle(day: cycleDay, phase: phase),
            ),
            const SizedBox(height: 16),
            _buildPillsRow(
              {
                'value': avgCycle.toString(),
                'label': 'Avg Cycle',
                'color': AppColors.primaryRose
              },
              {
                'value': avgPeriod.toString(),
                'label': 'Period Days',
                'color': const Color(0xFFC9A0D0)
              },
              {
                'value': '12',
                'label': 'Logged',
                'color': const Color(0xFF8AB88A)
              },
            ),
            const SizedBox(height: 24),
            const MiniCalendar(),
            const SizedBox(height: 24),
            const NextPeriodCard(),
          ],
        );
      case 'preg':
        return Column(
          children: [
            const Center(
              child: CycleCircle(
                day: 24,
                phase: '2nd Trimester 💙',
                color: Color(0xFF4A70B0),
                label: 'Weeks',
              ),
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
              {
                'value': '28',
                'label': 'Logs',
                'color': const Color(0xFF8AB88A)
              },
            ),
            const SizedBox(height: 24),
            _buildBabyCard(),
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
      case 'ovul':
        return Column(
          children: [
            const Center(
              child: CycleCircle(
                day: 14,
                phase: '🎯 Peak Fertile',
                color: Color(0xFF5A8E6A),
                label: 'Cycle Day',
              ),
            ),
            const SizedBox(height: 16),
            _buildPillsRow(
              {
                'value': 'Today',
                'label': 'Ovulation',
                'color': const Color(0xFF5A8E6A)
              },
              {
                'value': 'Mar 6',
                'label': 'Next Period',
                'color': AppColors.primaryRose
              },
              {
                'value': '28',
                'label': 'Cycle Len',
                'color': const Color(0xFF8AB88A)
              },
            ),
            const SizedBox(height: 24),
            _buildFertileBar(),
            const SizedBox(height: 24),
            _buildNextBanner(
              title: 'Ovulation Prediction',
              value: 'Today, Feb 21 🎯',
              sub: '89% confidence · Log BBT to confirm',
              color: const Color(0xFF5A8E6A),
              percentage: 89,
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildPillsRow(Map<String, dynamic> pill1, Map<String, dynamic> pill2,
      Map<String, dynamic> pill3) {
    return Row(
      children: [
        _buildStatPill(pill1['value'], pill1['label'], color: pill1['color']),
        const SizedBox(width: 8),
        _buildStatPill(pill2['value'], pill2['label'], color: pill2['color']),
        const SizedBox(width: 8),
        _buildStatPill(pill3['value'], pill3['label'], color: pill3['color']),
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

  Widget _buildBabyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A70B0).withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Week 24 • What\'s happening',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌽', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Baby is the size of a corn cob!',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'About 30cm and 600g. Baby\'s face is fully formed and she\'s practising breathing movements this week. Her brain is growing rapidly 💙',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMid.withOpacity(0.8),
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFertileBar() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🟢 Fertile Window — Day 10 to 16',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5A8E6A)),
          ),
          const SizedBox(height: 14),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FAF4),
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.72,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF78C890), Color(0xFF5A8E6A)]),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Day 10',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted)),
              Text('Peak (Day 14)',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5A8E6A))),
              Text('Day 16',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextBanner(
      {required String title,
      required String value,
      required String sub,
      required Color color,
      String? icon,
      int? percentage}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          if (icon != null)
            Text(icon, style: const TextStyle(fontSize: 32))
          else if (percentage != null)
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 5,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchModeCard(String currentMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Switch tracker',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 14),
          if (currentMode == 'period') ...[
            _buildSwitchBtn(
                '🤰 Expecting? → Track Pregnancy', () => _selectMode('preg')),
            const SizedBox(height: 8),
            _buildSwitchBtn('🌿 Trying to conceive? → Track Ovulation',
                () => _selectMode('ovul')),
          ] else if (currentMode == 'preg') ...[
            _buildSwitchBtn(
                '⚠️ Selected pregnancy by mistake? → Period Tracker',
                () => _selectMode('period'),
                urgent: true),
            const SizedBox(height: 8),
            _buildSwitchBtn('🌿 Not pregnant yet? → Ovulation Tracker',
                () => _selectMode('ovul')),
          ] else if (currentMode == 'ovul') ...[
            _buildSwitchBtn('🎉 Got a positive test? → Pregnancy Tracker',
                () => _selectMode('preg')),
            const SizedBox(height: 8),
            _buildSwitchBtn('🩸 Just track my period → Period Tracker',
                () => _selectMode('period')),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchBtn(String text, VoidCallback onTap,
      {bool urgent = false}) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          backgroundColor: urgent ? const Color(0xFFFFF5F5) : AppColors.bgMain,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: urgent ? const Color(0xFFF0B0B8) : AppColors.border,
                width: 1.5),
          ),
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: urgent ? const Color(0xFFD97B8A) : AppColors.textMid,
          ),
        ),
      ),
    );
  }

  void _selectMode(String mode) {
    // Navigate back to the journey for the selected mode
    context.go('/journey/$mode');
  }
}

class AppFAB extends StatelessWidget {
  const AppFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFF09090), Color(0xFFD97B8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97B8A).withOpacity(0.35),
            offset: const Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/log'),
          customBorder: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
