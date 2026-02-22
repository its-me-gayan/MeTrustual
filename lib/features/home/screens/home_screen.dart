import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../core/providers/mode_provider.dart';
import '../widgets/cycle_circle.dart';
import '../widgets/mini_calendar.dart';
import '../widgets/next_period_card.dart';
import '../providers/home_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isEditingNickname = false;
  final TextEditingController _nicknameController = TextEditingController();
  String _displayName = 'Sweetie';

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    
    setState(() {
      _displayName = prefs.getString('nickname') ?? user?.displayName ?? 'Sweetie';
    });
  }

  Future<void> _saveNickname(String newName) async {
    if (newName.isEmpty) newName = 'Sweetie';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', newName);
    
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(newName);
      
      final firestore = ref.read(firestoreProvider);
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('current')
          .update({'displayName': newName});
    }
    
    setState(() {
      _displayName = newName;
      _isEditingNickname = false;
    });
    
    if (mounted) {
      NotificationService.showSuccess(context, 'Nickname updated! ✨');
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeData = ref.watch(homeDataProvider);
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning ☀️',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onLongPress: () {
                            _nicknameController.text = _displayName;
                            setState(() => _isEditingNickname = true);
                          },
                          child: Text(
                            '$_displayName 👋',
                            style: GoogleFonts.nunito(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (_isEditingNickname)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border, width: 1.5),
                                    ),
                                    child: TextField(
                                      controller: _nicknameController,
                                      autofocus: true,
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter nickname',
                                        hintStyle: GoogleFonts.nunito(
                                          fontSize: 14,
                                          color: AppColors.textMuted,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                      onSubmitted: _saveNickname,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _saveNickname(_nicknameController.text.trim()),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRose,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.check,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setState(() => _isEditingNickname = false),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.textMuted.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.close,
                                        color: AppColors.textDark, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
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
      case '/insights':
        return 1;
      case '/education':
        return 2;
      case '/care':
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
            ),
            const SizedBox(height: 24),
            const PremiumGate(
              message: 'Unlock Advanced Calendar',
              child: MiniCalendar(),
            ),
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
            ),
            const SizedBox(height: 24),
            PremiumGate(
              message: 'Unlock Weekly Baby Updates',
              child: _buildBabyCard(),
            ),
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
            ),
            const SizedBox(height: 24),
            PremiumGate(
              message: 'Unlock Fertile Window Analysis',
              child: _buildFertileBar(),
            ),
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
        return const SizedBox.shrink();
    }
  }

  Widget _buildPillsRow(Map<String, dynamic> left, Map<String, dynamic> right) {
    return Row(
      children: [
        Expanded(child: _buildPill(left)),
        const SizedBox(width: 12),
        Expanded(child: _buildPill(right)),
      ],
    );
  }

  Widget _buildPill(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            data['value'],
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: data['color'],
            ),
          ),
          Text(
            data['label'],
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBabyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Text('👶', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baby is the size of a...',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  'Large Eggplant 🍆',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4A70B0),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildFertileBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fertile Window Probability',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (index) {
              final isPeak = index == 3;
              return Expanded(
                child: Container(
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isPeak
                        ? const Color(0xFF5A8E6A)
                        : const Color(0xFF5A8E6A).withOpacity(0.2 + (index * 0.1)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low', style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textMuted)),
              Text('Peak', style: GoogleFonts.nunito(fontSize: 10, color: const Color(0xFF5A8E6A), fontWeight: FontWeight.w900)),
              Text('Low', style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextBanner({
    required String title,
    required String value,
    required String sub,
    required Color color,
    String? icon,
    int? percentage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              if (icon != null) Text(icon, style: const TextStyle(fontSize: 16)),
              if (percentage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$percentage%',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchModeCard(String currentMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'Life stage changed?',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  'period',
                  '🩸 Period',
                  currentMode == 'period',
                  AppColors.primaryRose,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeButton(
                  'preg',
                  '🤰 Preg',
                  currentMode == 'preg',
                  const Color(0xFF4A70B0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeButton(
                  'ovul',
                  '🌿 Ovul',
                  currentMode == 'ovul',
                  const Color(0xFF5A8E6A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, String label, bool isActive, Color color) {
    return GestureDetector(
      onTap: () {
        ref.read(modeProvider.notifier).setMode(mode);
        NotificationService.showSuccess(context, 'Switched to $label mode!');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : AppColors.border,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isActive ? color : AppColors.textMid,
          ),
        ),
      ),
    );
  }
}
