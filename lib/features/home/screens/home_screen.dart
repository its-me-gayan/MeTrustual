import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_gate.dart';
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
  String? userNickname;
  bool _isEditingNickname = false;
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
  }

  Future<void> _loadUserNickname() async {
    // Load nickname from local storage or Firestore
    // For now, we'll use a placeholder
    setState(() {
      userNickname = 'Aisha'; // Default or loaded from storage
    });
  }

  Future<void> _saveNickname(String nickname) async {
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a nickname')),
      );
      return;
    }

    // Save to Firestore or local storage
    setState(() {
      userNickname = nickname;
      _isEditingNickname = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Nickname saved!')),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

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
                      GestureDetector(
                        onLongPress: () {
                          _nicknameController.text = userNickname ?? '';
                          setState(() => _isEditingNickname = true);
                        },
                        child: Text(
                          '${userNickname ?? user?.displayName ?? 'Aisha'} 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (_isEditingNickname)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: 200,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nicknameController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter nickname',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () =>
                                      _saveNickname(_nicknameController.text),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRose,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.check,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
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
            const PremiumGate(
              message: 'Unlock Advanced Calendar',
              child: SizedBox(),
            ),
            const SizedBox(height: 24),
            NextPeriodCard(
              nextDate: DateTime.now().add(const Duration(days: 7)),
              daysUntil: 7,
            ),
          ],
        );
      case 'preg':
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4A70B0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Week 24',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4A70B0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your baby is about the size of a mango 🥭',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A70B0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 'ovul':
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF5A8E6A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Cycle Day 14',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF5A8E6A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You\'re in your fertile window 🌿',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A8E6A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildPillsRow(
      Map<String, dynamic> pill1,
      Map<String, dynamic> pill2,
      Map<String, dynamic> pill3) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPill(pill1),
        _buildPill(pill2),
        _buildPill(pill3),
      ],
    );
  }

  Widget _buildPill(Map<String, dynamic> pill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (pill['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            pill['value'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: pill['color'],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pill['label'],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: pill['color'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchModeCard(String currentMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Want to switch trackers?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/mode-selection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRose,
              ),
              child: const Text('Switch Mode'),
            ),
          ),
        ],
      ),
    );
  }
}
