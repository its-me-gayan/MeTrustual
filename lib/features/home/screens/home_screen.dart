import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/providers/mode_provider.dart';
import '../models/home_mode_config.dart';
import '../providers/home_provider.dart';
import '../../../core/providers/period_journey_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../widgets/period_home_content.dart';
import '../widgets/pregnancy_home_content.dart';
import '../widgets/ovulation_home_content.dart';
import 'package:google_fonts/google_fonts.dart';

final _logsCountProvider = StreamProvider<int>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final uid = auth.currentUser?.uid;
  if (uid == null) return Stream.value(0);
  final mode = ref.watch(modeProvider);
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(uid)
      .collection('logs')
      .doc(mode)
      .collection('entries')
      .snapshots()
      .map((snap) => snap.size);
});

const _homeBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFFFF0F5),
    Color(0xFFFDE8F0),
    Color(0xFFFAF0F8),
    Color(0xFFFFF6F0)
  ],
  stops: [0.0, 0.35, 0.65, 1.0],
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditingNickname = false;
  final TextEditingController _nicknameController = TextEditingController();
  String _displayName = 'Sweetie';

  late final AnimationController _lunaPulseCtrl;
  late final Animation<double> _lunaPulse;

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _lunaPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _lunaPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lunaPulseCtrl, curve: Curves.easeInOut),
    );
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
    if (mounted)
      NotificationService.showSuccess(context, 'Nickname updated! ✨');
  }

  @override
  void dispose() {
    _lunaPulseCtrl.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeData = ref.watch(homeDataProvider);
    final currentMode = ref.watch(modeProvider);
    final modeConfig = HomeModeConfig.fromMode(currentMode);

    // Silently sync cycle anchor to Firebase whenever logs change
    ref.watch(cycleAnchorSyncProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Container(
        width: double.infinity,
        constraints:
            BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        decoration: const BoxDecoration(gradient: _homeBackgroundGradient),
        child: Stack(
          children: [
            Positioned(
                top: -60,
                right: -70,
                child: _GlowOrb(
                    size: 280, color: const Color(0xFFE8A84A), opacity: 0.05)),
            Positioned(
                bottom: 80,
                left: -60,
                child: _GlowOrb(
                    size: 260, color: const Color(0xFFD4639A), opacity: 0.06)),
            Positioned(
                top: MediaQuery.of(context).size.height * 0.4,
                right: -40,
                child: _GlowOrb(
                    size: 180, color: const Color(0xFF9B7FC7), opacity: 0.04)),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopRow(modeConfig.primaryColor),
                    const SizedBox(height: 30),
                    _buildModeSpecificContent(currentMode, homeData),
                    const SizedBox(height: 16),
                    _buildSwitchModeCard(currentMode),
                  ],
                ),
              ),
            ),
            Positioned(
                bottom: 92, right: 18, child: _buildLunaFab(modeConfig)),
          ],
        ),
      ),
      bottomNavigationBar:
          AppBottomNav(activeIndex: _getNavIndex(_currentRoute)),
      floatingActionButton: const AppFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildLunaFab(HomeModeConfig config) {
    return AnimatedBuilder(
      animation: _lunaPulse,
      builder: (context, child) {
        final ringSpread = 4.0 + (_lunaPulse.value * 4.0);
        final ringOpacity = 0.55 - (_lunaPulse.value * 0.35);
        final shadowOpacity = 0.38 + (_lunaPulse.value * 0.07);
        return GestureDetector(
          onTap: () => context.go('/luna'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: config.fabGradient,
              ),
              boxShadow: [
                BoxShadow(
                    color: config.fabShadow.withOpacity(shadowOpacity),
                    blurRadius: 20,
                    offset: const Offset(0, 6)),
                BoxShadow(
                    color: config.fabRing.withOpacity(ringOpacity),
                    blurRadius: 0,
                    spreadRadius: ringSpread),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌙',
                          style: TextStyle(fontSize: 22, height: 1.0)),
                      const SizedBox(height: 1),
                      Text('SOLUNA',
                          style: GoogleFonts.nunito(
                              fontSize: 5.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Positioned(top: 6, right: 6, child: _PulsingDot()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopRow(Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning ☀️',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted)),
              GestureDetector(
                onLongPress: () {
                  _nicknameController.text = _displayName;
                  setState(() => _isEditingNickname = true);
                },
                child: Text('$_displayName 👋',
                    style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark)),
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
                            border:
                                Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: TextField(
                            controller: _nicknameController,
                            autofocus: true,
                            style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark),
                            decoration: InputDecoration(
                              hintText: 'Enter nickname',
                              hintStyle: GoogleFonts.nunito(
                                  fontSize: 14, color: AppColors.textMuted),
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
                        onTap: () =>
                            _saveNickname(_nicknameController.text.trim()),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: BorderRadius.circular(12)),
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
              color: Colors.white.withOpacity(0.85),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: const Icon(Icons.person_outline, color: AppColors.textMid),
          ),
        ),
      ],
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
    final logsCount = ref.watch(_logsCountProvider).valueOrNull ?? 0;

    switch (currentMode) {
      case 'period':
        return PeriodHomeContent(logsCount: logsCount);
      case 'preg':
        return PregnancyHomeContent(logsCount: logsCount);
      case 'ovul':
        return OvulationHomeContent(logsCount: logsCount, homeData: homeData);
      default:
        return const SizedBox();
    }
  }

  Widget _buildSwitchModeCard(String currentMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
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

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.35)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF9C06A),
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb(
      {required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ),
      ),
    );
  }
}
