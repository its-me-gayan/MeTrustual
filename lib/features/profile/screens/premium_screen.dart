import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/premium_provider.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/theme/app_colors.dart';

// ── Plan enum ───────────────────────────────────────────────
enum PremiumPlan { monthly, yearly, lifetime }

final _selectedPlanProvider =
    StateProvider<PremiumPlan>((ref) => PremiumPlan.yearly);

// ── Feature model ────────────────────────────────────────────
class _FeatureItem {
  final String icon;
  final String label;
  final String desc;
  final List<Color> iconBg;
  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.desc,
    required this.iconBg,
  });
}

// ── Screen ───────────────────────────────────────────────────
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen>
    with TickerProviderStateMixin {
  // Animations
  late final AnimationController _fadeCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _floatAnim;

  bool _isLoading = false;

  // Design tokens — matching Soluna palette exactly
  static const _pink = Color(0xFFD97B8A);
  static const _pinkLight = Color(0xFFF09090);
  static const _pinkSoft = Color(0xFFFCE8E4);
  static const _textDark = Color(0xFF3D2828);
  static const _textMid = Color(0xFFB09090);
  static const _textSub = Color(0xFFC0A0A8);
  static const _green = Color(0xFF5A8E6A);
  static const _orange = Color(0xFFC97B3A);

  // Features list
  static const _features = [
    _FeatureItem(
      icon: '📊',
      label: 'Advanced Cycle Insights',
      desc: 'Predictions, trends & phase guidance',
      iconBg: [Color(0xFFFCE8E8), Color(0xFFFDD0D8)],
    ),
    _FeatureItem(
      icon: '🌙',
      label: 'Full Ritual Library',
      desc: '50+ guided self-care rituals',
      iconBg: [Color(0xFFF0E8FC), Color(0xFFE8D8F8)],
    ),
    _FeatureItem(
      icon: '📖',
      label: 'All Education Articles',
      desc: 'Expert-reviewed health content',
      iconBg: [Color(0xFFE8F8EC), Color(0xFFD8F0E0)],
    ),
    _FeatureItem(
      icon: '🤰',
      label: 'Pregnancy & Fertility Mode',
      desc: 'Dedicated tracking & tools',
      iconBg: [Color(0xFFFEF4E4), Color(0xFFFDE8C4)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _floatCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _floatAnim = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  // ── Purchase ────────────────────────────────────────────────
  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      // Until we integrate RevenueCat, we redirect to signup
      // final plan = ref.read(_selectedPlanProvider);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.push('/signup?premium=true');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Action failed. Please try again.',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: _pink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    HapticFeedback.lightImpact();
    // TODO: await ref.read(premiumProvider.notifier).restorePurchases();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Checking for existing purchases…',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(_selectedPlanProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F0),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF4F0),
                Color(0xFFFDE8F0),
                Color(0xFFEDE8FC),
                Color(0xFFE8EEFF),
              ],
              stops: [0.0, 0.4, 0.75, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // ── Floating deco emojis ──
                _FloatingDeco(
                    emoji: '🌸',
                    topFraction: 0.06,
                    leftFraction: 0.06,
                    anim: _floatAnim,
                    delay: 0.0),
                _FloatingDeco(
                    emoji: '✨',
                    topFraction: 0.11,
                    rightFraction: 0.08,
                    anim: _floatAnim,
                    delay: 0.35),
                _FloatingDeco(
                    emoji: '🌿',
                    topFraction: 0.54,
                    leftFraction: 0.04,
                    anim: _floatAnim,
                    delay: 0.65),
                _FloatingDeco(
                    emoji: '💫',
                    topFraction: 0.60,
                    rightFraction: 0.05,
                    anim: _floatAnim,
                    delay: 0.20),

                // ── Scrollable content ──
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
                  child: Column(
                    children: [
                      _buildHero(),
                      const SizedBox(height: 16),
                      _buildFeatures(),
                      const SizedBox(height: 14),
                      _buildPlanSelector(plan),
                      const SizedBox(height: 12),
                      _buildTrustStrip(),
                      const SizedBox(height: 14),
                      _buildCTA(plan),
                    ],
                  ),
                ),

                // ── Close button ──
                Positioned(
                  top: 12,
                  right: 14,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.72),
                        shape: BoxShape.circle,
                        border: Border.all(color: _pink.withOpacity(0.22)),
                      ),
                      child: Center(
                        child: Text('✕',
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _textSub)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero section ─────────────────────────────────────────────
  Widget _buildHero() {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Premium badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _pink.withOpacity(0.12),
              const Color(0xFFA078DC).withOpacity(0.10),
            ]),
            border: Border.all(color: _pink.withOpacity(0.22)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 5),
              Text(
                'SOLUNA PREMIUM',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _pink,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Breathing logo
        AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, __) => Transform.scale(
            scale: 1.0 + _floatAnim.value * 0.06,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFDE8C8), Color(0xFFF0D8F4)],
                ),
                boxShadow: [
                  BoxShadow(
                      color: _orange.withOpacity(0.20),
                      blurRadius: 28,
                      spreadRadius: 8),
                  BoxShadow(
                      color: const Color(0xFFFDE8C8).withOpacity(0.4),
                      blurRadius: 0,
                      spreadRadius: 8),
                ],
              ),
              child: const Center(
                  child: Text('🌸', style: TextStyle(fontSize: 32))),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Title
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _textDark,
                height: 1.25),
            children: const [
              TextSpan(text: 'Your body deserves\n'),
              TextSpan(text: 'full care', style: TextStyle(color: _orange)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unlock everything Soluna has to offer —\nyour complete wellness companion.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textMid,
              height: 1.6),
        ),
      ],
    );
  }

  // ── Features list ────────────────────────────────────────────
  Widget _buildFeatures() {
    return Column(
      children: _features
          .map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    border: Border.all(
                        color: const Color(0xFFFFD0D0).withOpacity(0.35)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: f.iconBg,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                            child: Text(f.icon,
                                style: const TextStyle(fontSize: 16))),
                      ),
                      const SizedBox(width: 10),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.label,
                                style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark)),
                            const SizedBox(height: 1),
                            Text(f.desc,
                                style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textSub)),
                          ],
                        ),
                      ),
                      // Tick
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [_pinkLight, _pink]),
                        ),
                        child: const Center(
                          child: Text('✓',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ── Plan selector ────────────────────────────────────────────
  Widget _buildPlanSelector(PremiumPlan selected) {
    return Row(
      children: [
        _PlanCard(
          plan: PremiumPlan.monthly,
          selected: selected,
          period: 'Monthly',
          price: '4.99',
          unit: '/ month',
          onTap: (p) => ref.read(_selectedPlanProvider.notifier).state = p,
        ),
        const SizedBox(width: 8),
        _PlanCard(
          plan: PremiumPlan.yearly,
          selected: selected,
          period: 'Yearly',
          price: '2.99',
          unit: '/ month',
          badge: 'Best Value',
          savingLabel: 'Save 40%',
          onTap: (p) => ref.read(_selectedPlanProvider.notifier).state = p,
        ),
        const SizedBox(width: 8),
        _PlanCard(
          plan: PremiumPlan.lifetime,
          selected: selected,
          period: 'Lifetime',
          price: '\$29',
          unit: 'one time',
          onTap: (p) => ref.read(_selectedPlanProvider.notifier).state = p,
        ),
      ],
    );
  }

  // ── Trust strip ──────────────────────────────────────────────
  Widget _buildTrustStrip() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _trustItem('🔒', 'Secure'),
        const SizedBox(width: 14),
        _trustItem('↩️', 'Cancel anytime'),
        const SizedBox(width: 14),
        _trustItem('🛡️', 'Private'),
      ],
    );
  }

  Widget _trustItem(String emoji, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 11, fontWeight: FontWeight.w800, color: _textSub)),
        ],
      );

  // ── CTA section ──────────────────────────────────────────────
  Widget _buildCTA(PremiumPlan plan) {
    final isLifetime = plan == PremiumPlan.lifetime;
    final btnLabel =
        isLifetime ? 'Get Lifetime Access 💫' : 'Start 3-Day Free Trial 🌸';
    final trialNote = isLifetime
        ? 'One-time payment. Yours forever.'
        : 'Free for 3 days, then \$35.99 / year. Cancel anytime.';

    return Column(
      children: [
        // Main button
        GestureDetector(
          onTap: _isLoading ? null : _handlePurchase,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_pinkLight, _pink, Color(0xFFC070A8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: _pink.withOpacity(0.40),
                    blurRadius: 22,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(btnLabel,
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.2)),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Trial note
        Text(trialNote,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 11, fontWeight: FontWeight.w700, color: _textSub)),
        const SizedBox(height: 12),

        // Links row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _textLink('Restore Purchase', _handleRestore),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                    color: _textSub.withOpacity(0.4), shape: BoxShape.circle)),
            _textLink('Privacy Policy', () {}),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                    color: _textSub.withOpacity(0.4), shape: BoxShape.circle)),
            _textLink('Terms', () {}),
          ],
        ),
      ],
    );
  }

  Widget _textLink(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _textSub,
                decoration: TextDecoration.underline,
                decorationColor: _textSub.withOpacity(0.5))),
      );
}

// ── Floating deco widget ─────────────────────────────────────
class _FloatingDeco extends StatelessWidget {
  final String emoji;
  final double topFraction;
  final double? leftFraction;
  final double? rightFraction;
  final Animation<double> anim;
  final double delay; // 0.0–1.0 phase offset

  const _FloatingDeco({
    required this.emoji,
    required this.topFraction,
    this.leftFraction,
    this.rightFraction,
    required this.anim,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return Positioned(
      top: h * topFraction,
      left: leftFraction != null ? w * leftFraction! : null,
      right: rightFraction != null ? w * rightFraction! : null,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: anim,
          builder: (_, __) {
            // Phase shift using sine trick
            final phase = (anim.value + delay) % 1.0;
            final offset = (phase < 0.5 ? phase : 1.0 - phase) * 2; // 0→1→0
            return Transform.translate(
              offset: Offset(0, -8 * offset),
              child: Opacity(
                opacity: 0.18,
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Plan card widget ─────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final PremiumPlan plan;
  final PremiumPlan selected;
  final String period;
  final String price;
  final String unit;
  final String? badge;
  final String? savingLabel;
  final ValueChanged<PremiumPlan> onTap;

  static const _pink = Color(0xFFD97B8A);
  static const _pinkLight = Color(0xFFF09090);
  static const _pinkSoft = Color(0xFFFCE8E4);
  static const _textDark = Color(0xFF3D2828);
  static const _textSub = Color(0xFFC0A0A8);
  static const _green = Color(0xFF5A8E6A);

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.period,
    required this.price,
    required this.unit,
    this.badge,
    this.savingLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = plan == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(plan);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(8, badge != null ? 18 : 14, 8, 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
            border: Border.all(
                color: isSelected ? _pink : _pinkSoft,
                width: isSelected ? 2.0 : 1.5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: _pink.withOpacity(0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          transform: Matrix4.translationValues(0, isSelected ? -3 : 0, 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Content
              Column(
                children: [
                  Text(period,
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _textSub,
                          letterSpacing: 0.4)),
                  const SizedBox(height: 4),
                  // Price
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? _pink : _textDark),
                      children: [
                        if (!price.startsWith('\$'))
                          TextSpan(
                              text: '\$',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? _pink : _textDark)),
                        TextSpan(text: price.replaceAll('\$', '')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(unit,
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _textSub)),
                  if (savingLabel != null) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(savingLabel!,
                          style: GoogleFonts.nunito(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: _green)),
                    ),
                  ],
                ],
              ),
              // Badge chip
              if (badge != null)
                Positioned(
                  top: -26,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient:
                            const LinearGradient(colors: [_pinkLight, _pink]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(badge!,
                          style: GoogleFonts.nunito(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
