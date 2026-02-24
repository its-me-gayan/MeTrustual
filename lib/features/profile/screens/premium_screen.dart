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

// ─────────────────────────────────────────────────────────────
//  Mode → accent palette  [base, light, soft-bg]
//
//  period  → rose   (matches home screen / PIN)
//  preg    → blue   (matches pregnancy CycleCircle)
//  ovul    → green  (matches ovulation CycleCircle)
// ─────────────────────────────────────────────────────────────
List<Color> _modeAccent(String mode) {
  switch (mode) {
    case 'preg':
      return const [
        Color(0xFF5878B8), // base
        Color(0xFF7898CC), // light
        Color(0xFFECF0FA), // soft bg
      ];
    case 'ovul':
      return const [
        Color(0xFF5A8E6A), // base
        Color(0xFF7AAE8A), // light
        Color(0xFFECF6EE), // soft bg
      ];
    default: // 'period'
      return const [
        Color(0xFFD4849A), // base
        Color(0xFFE8A0B0), // light
        Color(0xFFFCEEF0), // soft bg
      ];
  }
}

/// Slightly deeper variant used as the button gradient's trailing stop.
Color _modeAccentDeep(String mode) {
  switch (mode) {
    case 'preg':
      return const Color(0xFF4A68A8);
    case 'ovul':
      return const Color(0xFF4A7E5A);
    default:
      return const Color(0xFFC07898);
  }
}

// ── Screen ───────────────────────────────────────────────────
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _floatAnim;

  bool _isLoading = false;

  // ── Mode-independent tokens ──────────────────────────────────
  static const _textDark = Color(0xFF3D2828);
  static const _textMid = Color(0xFFB8A0A8);
  static const _textSub = Color(0xFFC8AEB8);
  static const _green = Color(0xFF6A9E7A);
  static const _orange = Color(0xFFCE8B4A);

  static const _backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF0F5),
      Color(0xFFFDE8F0),
      Color(0xFFFAF0F8),
      Color(0xFFFFF6F0),
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  static const _features = [
    _FeatureItem(
      icon: '📊',
      label: 'Advanced Cycle Insights',
      desc: 'Predictions, trends & phase guidance',
      iconBg: [Color(0xFFFEF0F0), Color(0xFFFDE0E8)],
    ),
    _FeatureItem(
      icon: '🌙',
      label: 'Full Ritual Library',
      desc: '50+ guided self-care rituals',
      iconBg: [Color(0xFFF5F0FC), Color(0xFFEEE4F8)],
    ),
    _FeatureItem(
      icon: '📖',
      label: 'All Education Articles',
      desc: 'Expert-reviewed health content',
      iconBg: [Color(0xFFEEF8F0), Color(0xFFE4F4E8)],
    ),
    _FeatureItem(
      icon: '🤰',
      label: 'Pregnancy & Fertility Mode',
      desc: 'Dedicated tracking & tools',
      iconBg: [Color(0xFFFEF6EC), Color(0xFFFEEED4)],
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

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.push('/signup?premium=true');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Action failed. Please try again.',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: _modeAccent(ref.read(modeProvider))[0],
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Checking for existing purchases…',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(_selectedPlanProvider);
    final mode = ref.watch(modeProvider);
    final accent = _modeAccent(mode); // [base, light, soft]

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          width: double.infinity,
          constraints:
              BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          decoration: const BoxDecoration(gradient: _backgroundGradient),
          child: Stack(
            children: [
              // ── Ambient glow orbs — hue follows mode ──
              Positioned(
                top: -70,
                right: -70,
                child: _GlowOrb(size: 300, color: accent[1], opacity: 0.07),
              ),
              Positioned(
                bottom: 60,
                left: -60,
                child: _GlowOrb(size: 260, color: accent[0], opacity: 0.06),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.45,
                right: -40,
                child: _GlowOrb(
                    size: 180, color: const Color(0xFFA090C8), opacity: 0.04),
              ),

              // ── Floating deco ──
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

              // ── Content ──
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
                  child: Column(
                    children: [
                      _buildHero(accent),
                      const SizedBox(height: 16),
                      _buildFeatures(accent),
                      const SizedBox(height: 14),
                      _buildPlanSelector(plan, mode, accent),
                      const SizedBox(height: 12),
                      _buildTrustStrip(),
                      const SizedBox(height: 14),
                      _buildCTA(plan, mode, accent),
                    ],
                  ),
                ),
              ),

              // ── Close button ──
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 14,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.80),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent[0].withOpacity(0.18)),
                      boxShadow: [
                        BoxShadow(
                            color: accent[0].withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
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
    );
  }

  // ── Hero ──────────────────────────────────────────────────────
  Widget _buildHero(List<Color> accent) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Premium badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            // Always rose — not mode-dependent
            color: const Color(0xFFFCEEF0).withOpacity(0.80),
            border:
                Border.all(color: const Color(0xFFD4849A).withOpacity(0.22)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 5),
              Text('SOLUNA PREMIUM',
                  style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFD4849A),
                      letterSpacing: 0.8)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Breathing logo orb
        AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, __) => Transform.scale(
            scale: 1.0 + _floatAnim.value * 0.06,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Always warm rose/cream — not mode-dependent
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFEEED8), Color(0xFFF4E4F4)],
                ),
                boxShadow: [
                  BoxShadow(
                      color: Color(0xFFCE8B4A).withOpacity(0.14),
                      blurRadius: 28,
                      spreadRadius: 6),
                  BoxShadow(
                      color: Color(0xFFFEEED8).withOpacity(0.40),
                      blurRadius: 0,
                      spreadRadius: 6),
                ],
              ),
              child: const Center(
                  child: Text('🌸', style: TextStyle(fontSize: 32))),
            ),
          ),
        ),
        const SizedBox(height: 14),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _textDark,
                height: 1.25),
            children: [
              const TextSpan(text: 'Your body deserves\n'),
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

  // ── Features ──────────────────────────────────────────────────
  Widget _buildFeatures(List<Color> accent) {
    return Column(
      children: _features
          .map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.82),
                    border: Border.all(
                        color: accent[0].withOpacity(0.12), width: 1.2),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: accent[0].withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    children: [
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
                      // Tick — mode-tinted
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient:
                              LinearGradient(colors: [accent[1], accent[0]]),
                        ),
                        child: const Center(
                            child: Text('✓',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900))),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ── Plan selector ─────────────────────────────────────────────
  Widget _buildPlanSelector(
      PremiumPlan selected, String mode, List<Color> accent) {
    return Row(
      children: [
        _PlanCard(
            plan: PremiumPlan.monthly,
            selected: selected,
            period: 'Monthly',
            price: '4.99',
            unit: '/ month',
            accent: accent,
            onTap: (p) => ref.read(_selectedPlanProvider.notifier).state = p),
        const SizedBox(width: 8),
        _PlanCard(
            plan: PremiumPlan.yearly,
            selected: selected,
            period: 'Yearly',
            price: '2.99',
            unit: '/ month',
            badge: 'Best Value',
            savingLabel: 'Save 40%',
            accent: accent,
            onTap: (p) => ref.read(_selectedPlanProvider.notifier).state = p),
        const SizedBox(width: 8),
        _PlanCard(
            plan: PremiumPlan.lifetime,
            selected: selected,
            period: 'Lifetime',
            price: '\$29',
            unit: 'one time',
            accent: accent,
            onTap: (p) => ref.read(_selectedPlanProvider.notifier).state = p),
      ],
    );
  }

  // ── Trust strip ───────────────────────────────────────────────
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

  // ── CTA ───────────────────────────────────────────────────────
  Widget _buildCTA(PremiumPlan plan, String mode, List<Color> accent) {
    final isLifetime = plan == PremiumPlan.lifetime;
    final btnLabel =
        isLifetime ? 'Get Lifetime Access 💫' : 'Start 3-Day Free Trial 🌸';
    final trialNote = isLifetime
        ? 'One-time payment. Yours forever.'
        : 'Free for 3 days, then \$35.99 / year. Cancel anytime.';

    return Column(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _handlePurchase,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent[1], accent[0], _modeAccentDeep(mode)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: accent[0].withOpacity(0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 7))
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
        Text(trialNote,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 11, fontWeight: FontWeight.w700, color: _textSub)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _textLink('Restore Purchase', _handleRestore),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                    color: _textSub.withOpacity(0.35), shape: BoxShape.circle)),
            _textLink('Privacy Policy', () {}),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                    color: _textSub.withOpacity(0.35), shape: BoxShape.circle)),
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
                decorationColor: _textSub.withOpacity(0.4))),
      );
}

// ══════════════════════════════════════════════════════════════
//  Ambient glow orb
// ══════════════════════════════════════════════════════════════
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb(
      {required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [color.withOpacity(opacity), color.withOpacity(0)]),
        ),
      );
}

// ── Floating deco ─────────────────────────────────────────────
class _FloatingDeco extends StatelessWidget {
  final String emoji;
  final double topFraction;
  final double? leftFraction;
  final double? rightFraction;
  final Animation<double> anim;
  final double delay;

  const _FloatingDeco(
      {required this.emoji,
      required this.topFraction,
      this.leftFraction,
      this.rightFraction,
      required this.anim,
      required this.delay});

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
            final phase = (anim.value + delay) % 1.0;
            final offset = (phase < 0.5 ? phase : 1.0 - phase) * 2;
            return Transform.translate(
              offset: Offset(0, -8 * offset),
              child: Opacity(
                  opacity: 0.16,
                  child: Text(emoji, style: const TextStyle(fontSize: 22))),
            );
          },
        ),
      ),
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final PremiumPlan plan;
  final PremiumPlan selected;
  final String period;
  final String price;
  final String unit;
  final String? badge;
  final String? savingLabel;
  final List<Color> accent; // [base, light, soft]
  final ValueChanged<PremiumPlan> onTap;

  static const _textDark = Color(0xFF3D2828);
  static const _textSub = Color(0xFFC8AEB8);
  static const _green = Color(0xFF6A9E7A);

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.period,
    required this.price,
    required this.unit,
    this.badge,
    this.savingLabel,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = plan == selected;
    final base = accent[0];
    final light = accent[1];
    final soft = accent[2];

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
            // Selected: soft mode-tinted wash; unselected: plain frosted white
            color: isSelected
                ? soft.withOpacity(0.55)
                : Colors.white.withOpacity(0.75),
            border: Border.all(
                color: isSelected ? base : soft, width: isSelected ? 1.8 : 1.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: base.withOpacity(0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 5))
                  ]
                : [
                    BoxShadow(
                        color: base.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
          ),
          transform: Matrix4.translationValues(0, isSelected ? -3 : 0, 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Text(period,
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _textSub,
                          letterSpacing: 0.4)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? base : _textDark),
                      children: [
                        if (!price.startsWith('\$'))
                          TextSpan(
                              text: '\$',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? base : _textDark)),
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
                          color: _green.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(savingLabel!,
                          style: GoogleFonts.nunito(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: _green)),
                    ),
                  ],
                ],
              ),
              // Badge chip — mode-tinted
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
                        gradient: LinearGradient(colors: [light, base]),
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
