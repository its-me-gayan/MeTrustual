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

// ── Mode → theme color (shared helper) ───────────────────────
Color modeColor(String mode) {
  switch (mode) {
    case 'preg':
      return const Color(0xFF4A70B0);
    case 'ovul':
      return const Color(0xFF5A8E6A);
    default:
      return AppColors.primaryRose;
  }
}

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
      _displayName =
          prefs.getString('nickname') ?? user?.displayName ?? 'Sweetie';
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
    final themeColor = modeColor(currentMode);

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
                                      border: Border.all(
                                          color: AppColors.border, width: 1.5),
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
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                      ),
                                      onSubmitted: _saveNickname,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _saveNickname(
                                      _nicknameController.text.trim()),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: themeColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.check,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _isEditingNickname = false),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.textMuted.withOpacity(0.2),
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
            Center(child: CycleCircle(day: cycleDay, phase: phase)),
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
        return const SizedBox();
    }
  }

  Widget _buildPillsRow(
      Map<String, dynamic> pill1, Map<String, dynamic> pill2) {
    return Row(
      children: [
        _buildStatPill(pill1['value'], pill1['label'], color: pill1['color']),
        const SizedBox(width: 8),
        _buildStatPill(pill2['value'], pill2['label'], color: pill2['color']),
      ],
    );
  }

  Widget _buildStatPill(String value, String label, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color ?? AppColors.primaryRose,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.nunito(
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
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('👶 Baby Updates',
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          Text('Week 24: Baby is about the size of a papaya!',
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMid)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A70B0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Baby weight: ~600g • Length: ~30cm',
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4A70B0))),
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
          Text('🌱 Fertile Window',
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.5,
              minHeight: 8,
              backgroundColor: const Color(0xFF5A8E6A).withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF5A8E6A)),
            ),
          ),
          const SizedBox(height: 8),
          Text('Peak fertility: Today & Tomorrow',
              style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted)),
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
              Text(title,
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.5)),
              if (icon != null)
                Text(icon, style: const TextStyle(fontSize: 16)),
              if (percentage != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$percentage%',
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: color)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(sub,
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMid)),
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
          Text('Switch tracker',
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: 0.2)),
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
          backgroundColor:
              urgent ? const Color(0xFFFFF5F5) : AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: urgent ? const Color(0xFFF0B0B8) : AppColors.border,
                width: 1.5),
          ),
          alignment: Alignment.centerLeft,
        ),
        child: Text(text,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: urgent ? const Color(0xFFD97B8A) : AppColors.textMid)),
      ),
    );
  }

  Future<void> _selectMode(String mode) async {
    await ref.read(modeProvider.notifier).resetJourney();
    if (mounted) context.go('/journey/$mode');
  }
}
