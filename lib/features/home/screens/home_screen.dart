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
import '../../../core/providers/period_journey_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

List<Color> _modeFabGradient(String mode) {
  switch (mode) {
    case 'preg':
      return [const Color(0xFF7AA0E0), const Color(0xFF4A70B0)];
    case 'ovul':
      return [const Color(0xFF78C890), const Color(0xFF5A8E6A)];
    default:
      return [const Color(0xFFE8789A), const Color(0xFFC95678)];
  }
}

Color _modeFabShadow(String mode) {
  switch (mode) {
    case 'preg':
      return const Color(0xFF4A70B0);
    case 'ovul':
      return const Color(0xFF5A8E6A);
    default:
      return const Color(0xFFC95678);
  }
}

Color _modeFabRing(String mode) {
  switch (mode) {
    case 'preg':
      return const Color(0xFFC8DCF8);
    case 'ovul':
      return const Color(0xFFBEE6CD);
    default:
      return const Color(0xFFFCDCE6);
  }
}

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
    final themeColor = modeColor(currentMode);

    // ── Silently sync cycle anchor to Firebase whenever logs change ──────────
    // Handles two cases:
    //   1. User skipped "last period" during onboarding → writes first detected start
    //   2. A new period appears in logs that is newer than what Firebase has
    //      → updates lastPeriod, cycleLen, periodLen so predictions stay accurate
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
                    _buildTopRow(themeColor),
                    const SizedBox(height: 30),
                    _buildModeSpecificContent(currentMode, homeData),
                    const SizedBox(height: 16),
                    _buildSwitchModeCard(currentMode),
                  ],
                ),
              ),
            ),
            Positioned(
                bottom: 92, right: 18, child: _buildLunaFab(currentMode)),
          ],
        ),
      ),
      bottomNavigationBar:
          AppBottomNav(activeIndex: _getNavIndex(_currentRoute)),
      floatingActionButton: const AppFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildLunaFab(String mode) {
    final gradientColors = _modeFabGradient(mode);
    final shadowColor = _modeFabShadow(mode);
    final ringColor = _modeFabRing(mode);

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
                colors: gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                    color: shadowColor.withOpacity(shadowOpacity),
                    blurRadius: 20,
                    offset: const Offset(0, 6)),
                BoxShadow(
                    color: ringColor.withOpacity(ringOpacity),
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
      // ── PERIOD ── circle → pills → calendar → next period card ──
      case 'period':
        final journey = ref.watch(periodHomeDataProvider);
        final cycleDay = journey?.cycleDay ?? 0;
        final phaseLabel = journey?.phaseLabel ?? 'Loading… 🌸';
        final cycleLen = journey?.cycleLen ?? 28;
        final periodLen = journey?.periodLen ?? 5;

        return Column(
          children: [
            Center(child: CycleCircle(day: cycleDay, phase: phaseLabel)),
            const SizedBox(height: 16),
            _buildPillsRow(
              {
                'value': cycleLen.toString(),
                'label': 'Avg Cycle',
                'color': AppColors.primaryRose
              },
              {
                'value': periodLen.toString(),
                'label': 'Period Days',
                'color': const Color(0xFFC9A0D0)
              },
              third: {
                'value': logsCount.toString(),
                'label': 'Logged',
                'color': const Color(0xFF8AB88A)
              },
            ),
            const SizedBox(height: 16),
            _buildPredictionBanner(journey, cycleDay, cycleLen),
            const SizedBox(height: 16),
            const PremiumGate(
              message: 'Unlock Advanced Calendar',
              child: MiniCalendar(),
            ),
          ],
        );

      // ── PREGNANCY ──────────────────────────────────────────────
      case 'preg':
        return Column(
          children: [
            const Center(
              child: CycleCircle(
                  day: 24,
                  phase: '2nd Trimester 💙',
                  color: Color(0xFF4A70B0),
                  label: 'Weeks'),
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
              third: {
                'value': logsCount.toString(),
                'label': 'Logs',
                'color': const Color(0xFF8AB88A)
              },
            ),
            const SizedBox(height: 24),
            PremiumGate(
                message: 'Unlock Weekly Baby Updates', child: _buildBabyCard()),
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

      // ── OVULATION ──────────────────────────────────────────────
      case 'ovul':
        final avgCycleOvul = homeData?['prediction']?.averageLength ?? 28;
        return Column(
          children: [
            const Center(
              child: CycleCircle(
                  day: 14,
                  phase: '🎯 Peak Fertile',
                  color: Color(0xFF5A8E6A),
                  label: 'Cycle Day'),
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
              third: {
                'value': avgCycleOvul.toString(),
                'label': 'Cycle Len',
                'color': const Color(0xFF8AB88A)
              },
            ),
            const SizedBox(height: 24),
            PremiumGate(
                message: 'Unlock Fertile Window Analysis',
                child: _buildFertileBar()),
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

  Widget _buildPredictionBanner(
      PeriodHomeData? journey, int cycleDay, int cycleLen) {
    final fmt = DateFormat('MMM d');
    final fmtShort = DateFormat('d');

    // ── 1. Best source: real AI prediction from AiPredictionService ────────
    final aiResult = journey?.aiResult;

    // ── 2. Fallback: SmartPredictionEngine math (no API call needed) ───────
    //    Uses the blended cycle length already computed in PeriodHomeData
    final smartCycleLen = journey?.cycleLen ?? cycleLen; // blended by engine
    final daysUntilPeriod = (smartCycleLen - cycleDay).clamp(0, smartCycleLen);
    final mathNextPeriod = DateTime.now().add(Duration(days: daysUntilPeriod));

    // Pick the best available next period date
    final nextPeriod = aiResult?.nextPeriod ?? mathNextPeriod;

    // Confidence: use AI value if available, otherwise from PeriodHomeData
    final confidencePct = aiResult?.confidencePct ??
        ((journey?.learningProgress ?? 0.35) * 100).round();

    // Source label under next period
    final isAi = aiResult != null;
    final aiLoading = journey?.aiLoading ?? false;
    final periodSub = aiLoading ? 'Calculating…' : '±2 days · $confidencePct%';

    // ── 3. Fertile window — always derived from nextPeriod (biology) ───────
    //    Ovulation ≈ 14 days before next period (luteal phase is fixed ~14d)
    //    Fertile window = ovulation −5 → ovulation +1
    final ovulationDate = nextPeriod.subtract(const Duration(days: 14));
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));

    final nextPeriodStr = fmt.format(nextPeriod);
    final fertileStr =
        '${fmt.format(fertileStart)}–${fmtShort.format(fertileEnd)}';
    final ovulStr = fmt.format(ovulationDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF5F8), Color(0xFFFDE8F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0C0D0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row — shows AI vs math source
          Row(
            children: [
              Text(
                aiLoading
                    ? '✨ Calculating…'
                    : isAi
                        ? '🤖 AI Predictions'
                        : '🔮 Predictions',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFC080A0),
                    letterSpacing: 0.5),
              ),
              const Spacer(),
              if (isAi && !aiLoading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B7FC7).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('AI-powered',
                      style: GoogleFonts.nunito(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF9B7FC7))),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Two-column pred items
          aiLoading
              ? const SizedBox(
                  height: 40,
                  child: Center(
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFC080A0))),
                  ),
                )
              : IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildPredItem(
                              label: '🩸 Next period',
                              value: nextPeriodStr,
                              sub: periodSub)),
                      Container(
                          width: 1,
                          color: const Color(0xFFF0D8E0),
                          margin: const EdgeInsets.symmetric(horizontal: 10)),
                      Expanded(
                          child: _buildPredItem(
                              label: '🌿 Fertile window',
                              value: fertileStr,
                              sub: 'Ovulation ~$ovulStr')),
                    ],
                  ),
                ),

          // AI insight (only when AI result has one)
          if (isAi && aiResult!.insight.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF9B7FC7).withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(aiResult.insight,
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7B5FC7),
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPredItem(
      {required String label, required String value, required String sub}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFD0A0B8))),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark)),
        const SizedBox(height: 1),
        Text(sub,
            style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD0A0B8))),
      ],
    );
  }

  Widget _buildPillsRow(Map<String, dynamic> pill1, Map<String, dynamic> pill2,
      {Map<String, dynamic>? third}) {
    return Row(
      children: [
        _buildStatPill(pill1['value'], pill1['label'], color: pill1['color']),
        const SizedBox(width: 8),
        _buildStatPill(pill2['value'], pill2['label'], color: pill2['color']),
        if (third != null) ...[
          const SizedBox(width: 8),
          _buildStatPill(third['value'], third['label'], color: third['color']),
        ],
      ],
    );
  }

  Widget _buildStatPill(String value, String label, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color ?? AppColors.primaryRose)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildBabyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF4A70B0).withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 16)
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
        color: Colors.white.withOpacity(0.88),
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
