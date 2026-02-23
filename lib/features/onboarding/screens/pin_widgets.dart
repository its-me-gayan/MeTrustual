import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pin_constants.dart';

// ═══════════════════════════════════════════════════════
//  PIN WIDGETS
//  All reusable UI components shared between
//  PinVerificationScreen and ForgotPinOverlay.
// ═══════════════════════════════════════════════════════

// ── Numpad ───────────────────────────────────────────

/// A single circular numpad key.
/// Set [isAction] for the backspace / biometric keys.
/// Set [isEmpty] to render a transparent placeholder cell.
class PinNumKey extends StatelessWidget {
  final String digit;
  final String sub;
  final bool isAction;
  final bool isEmpty;
  final bool smaller;
  final VoidCallback? onTap;

  const PinNumKey({
    super.key,
    required this.digit,
    this.sub = '',
    this.isAction = false,
    this.isEmpty = false,
    this.smaller = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAction ? Colors.transparent : Colors.white.withOpacity(0.80),
          border: isAction
              ? null
              : Border.all(
                  color: PinColors.peachBorder.withOpacity(0.9),
                  width: 1.5,
                ),
          boxShadow: isAction
              ? null
              : [
                  BoxShadow(
                    color: PinColors.roseDeep.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: TextStyle(
                fontSize: isAction ? (smaller ? 18 : 20) : (smaller ? 22 : 26),
                fontWeight: FontWeight.w900,
                color: isAction ? PinColors.textHint : PinColors.darkBrown,
                height: 1.0,
              ),
            ),
            if (sub.isNotEmpty)
              Text(
                sub,
                style: TextStyle(
                  fontSize: smaller ? 6 : 7,
                  fontWeight: FontWeight.w800,
                  color: PinColors.textSubtle,
                  letterSpacing: 0.8,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A full 3×4 numpad grid.
/// Calls [onKey] with the digit string, [onBiometric] for the 🪪 key,
/// and [onDelete] for ⌫.  Set [disabled] to grey-out all taps.
class PinNumpad extends StatelessWidget {
  final void Function(String digit) onKey;
  final VoidCallback? onBiometric;
  final VoidCallback onDelete;
  final bool disabled;
  final bool smaller;

  const PinNumpad({
    super.key,
    required this.onKey,
    required this.onDelete,
    this.onBiometric,
    this.disabled = false,
    this.smaller = false,
  });

  @override
  Widget build(BuildContext context) {
    VoidCallback? tap(String d) => disabled ? null : () => onKey(d);

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: smaller ? 8 : 10,
      crossAxisSpacing: smaller ? 8 : 10,
      childAspectRatio: smaller ? 1.6 : 1.2,
      children: [
        for (final (digit, sub) in kNumpadKeys)
          PinNumKey(
              digit: digit, sub: sub, onTap: tap(digit), smaller: smaller),
        PinNumKey(
          digit: '🪪',
          isAction: true,
          smaller: smaller,
          onTap: disabled ? null : onBiometric,
        ),
        PinNumKey(digit: '0', onTap: tap('0'), smaller: smaller),
        PinNumKey(
          digit: '⌫',
          isAction: true,
          smaller: smaller,
          onTap: disabled ? null : onDelete,
        ),
      ],
    );
  }
}

/// Numpad without the biometric key (used in forgot-PIN steps).
class OtpNumpad extends StatelessWidget {
  final void Function(String digit) onKey;
  final VoidCallback onDelete;
  final bool disabled;

  const OtpNumpad({
    super.key,
    required this.onKey,
    required this.onDelete,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    VoidCallback? tap(String d) => disabled ? null : () => onKey(d);

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        for (final (digit, sub) in kNumpadKeys)
          PinNumKey(digit: digit, sub: sub, onTap: tap(digit), smaller: true),
        const PinNumKey(digit: '', isEmpty: true, smaller: true),
        PinNumKey(digit: '0', onTap: tap('0'), smaller: true),
        PinNumKey(
          digit: '⌫',
          isAction: true,
          smaller: true,
          onTap: disabled ? null : onDelete,
        ),
      ],
    );
  }
}

// ── PIN dot indicators ────────────────────────────────

enum PinDotState { empty, filled, error, success }

/// A single animated PIN dot.
class PinDot extends StatelessWidget {
  final PinDotState state;

  const PinDot({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final filled = state != PinDotState.empty;
    LinearGradient? grad;
    Color borderColor;

    switch (state) {
      case PinDotState.filled:
        grad = kRoseGradient;
        borderColor = PinColors.roseDeep;
        break;
      case PinDotState.error:
        grad = kErrorGradient;
        borderColor = PinColors.errorRed;
        break;
      case PinDotState.success:
        grad = kGreenGradient;
        borderColor = PinColors.greenSuccess;
        break;
      case PinDotState.empty:
        borderColor = PinColors.roseDeep.withOpacity(0.25);
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Container(
        key: ValueKey(state),
        margin: const EdgeInsets.symmetric(horizontal: 7),
        width: filled ? 16 : 14,
        height: filled ? 16 : 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: grad,
          color: filled ? null : PinColors.roseDeep.withOpacity(0.15),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.40),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
      ),
    );
  }
}

/// A row of 4 PIN dots with an optional horizontal shake animation.
class PinDotRow extends StatelessWidget {
  final int filledCount; // 0–4
  final bool isError;
  final Animation<double> shakeAnimation;

  const PinDotRow({
    super.key,
    required this.filledCount,
    required this.isError,
    required this.shakeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        final offset =
            isError ? math.sin(shakeAnimation.value * math.pi * 4) * 6.0 : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          PinDotState state;
          if (i < filledCount) {
            state = isError ? PinDotState.error : PinDotState.filled;
          } else {
            state = PinDotState.empty;
          }
          return PinDot(state: state);
        }),
      ),
    );
  }
}

/// A row of 4 dots with explicit per-dot state (used in forgot-PIN steps).
class ForgotPinDotRow extends StatelessWidget {
  final int filledCount;
  final bool isError;
  final bool isSuccess;
  final Animation<double> shakeAnimation;

  const ForgotPinDotRow({
    super.key,
    required this.filledCount,
    this.isError = false,
    this.isSuccess = false,
    required this.shakeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        final offset =
            isError ? math.sin(shakeAnimation.value * math.pi * 4) * 6.0 : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          PinDotState state;
          if (i < filledCount) {
            if (isSuccess) {
              state = PinDotState.success;
            } else if (isError) {
              state = PinDotState.error;
            } else {
              state = PinDotState.filled;
            }
          } else {
            state = PinDotState.empty;
          }
          return PinDot(state: state);
        }),
      ),
    );
  }
}

// ── OTP cells ─────────────────────────────────────────

/// 6-cell OTP input display (read-only — driven by parent state).
class OtpCellRow extends StatelessWidget {
  final List<String> entered; // up to 6 digits
  final bool verified;

  const OtpCellRow({super.key, required this.entered, this.verified = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < entered.length;
        final isVerified = verified && filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 42,
          height: 52,
          decoration: BoxDecoration(
            color: isVerified
                ? PinColors.greenSuccess.withOpacity(0.06)
                : Colors.white.withOpacity(0.85),
            border: Border.all(
              color: isVerified
                  ? PinColors.greenSuccess
                  : (i == entered.length && !verified
                      ? PinColors.roseDeep
                      : (filled ? PinColors.roseDeep : PinColors.peachBorder)),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              filled ? entered[i] : '–',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isVerified
                    ? PinColors.greenSuccess
                    : (filled ? PinColors.darkBrown : PinColors.textSubtle),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Ambient decoration ────────────────────────────────

/// Animated ambient ring (part of the pulsing rings behind the logo).
class PinAmbientRing extends StatelessWidget {
  final double progress; // 0 → 1
  final double size;
  final Color? color;

  const PinAmbientRing({
    super.key,
    required this.progress,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = (1.0 - progress).clamp(0.0, 0.8) * 0.8;
    final scale = 0.85 + 0.3 * progress;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: (color ?? PinColors.roseDeep.withOpacity(0.10))
                .withOpacity(opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Three concentric pulsing rings driven by a single [AnimationController].
class PinAmbientRings extends StatelessWidget {
  final AnimationController controller;

  const PinAmbientRings({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              PinAmbientRing(progress: controller.value % 1.0, size: 110),
              PinAmbientRing(
                  progress: (controller.value + 0.25) % 1.0, size: 170),
              PinAmbientRing(
                  progress: (controller.value + 0.5) % 1.0,
                  size: 240,
                  color: PinColors.roseDeep.withOpacity(0.05)),
            ],
          );
        },
      ),
    );
  }
}

/// Configuration data for a single floating petal.
class PetalConfig {
  final double left; // fraction of screen width
  final String emoji;
  final double size;
  final int duration; // ms
  final int delay; // ms

  const PetalConfig({
    required this.left,
    required this.emoji,
    required this.size,
    required this.duration,
    required this.delay,
  });
}

/// An animated petal that floats upward from the bottom of the screen.
class FloatingPetal extends StatefulWidget {
  final PetalConfig config;

  const FloatingPetal({super.key, required this.config});

  @override
  State<FloatingPetal> createState() => _FloatingPetalState();
}

class _FloatingPetalState extends State<FloatingPetal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.config.duration),
    )..repeat();
    Future.delayed(Duration(milliseconds: widget.config.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        double opacity = 0;
        if (t > 0.08) opacity = math.min(1.0, (t - 0.08) / 0.08) * 0.5;
        if (t > 0.85) opacity *= math.max(0.0, 1.0 - (t - 0.85) / 0.15);
        return Positioned(
          left: screenW * widget.config.left,
          bottom: 0,
          child: Transform.translate(
            offset: Offset(0, -screenH * t),
            child: Transform.rotate(
              angle: t * math.pi * 4,
              child: Opacity(
                opacity: opacity,
                child: Text(
                  widget.config.emoji,
                  style: TextStyle(fontSize: widget.config.size),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Ambient radial glow orb — purely decorative.
class GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const GlowOrb({
    super.key,
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withOpacity(opacity),
            color.withOpacity(0.0),
          ]),
        ),
      ),
    );
  }
}

// ── Success screen decorations ────────────────────────

/// A single pulsing ring used on the "PIN Updated" success step.
class SuccessRing extends StatefulWidget {
  final int index; // 0, 1, or 2

  const SuccessRing({super.key, required this.index});

  @override
  State<SuccessRing> createState() => _SuccessRingState();
}

class _SuccessRingState extends State<SuccessRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    Future.delayed(Duration(milliseconds: widget.index * 500), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sizes = [60.0, 85.0, 100.0];
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Opacity(
          opacity: (1.0 - t).clamp(0.0, 0.7),
          child: Transform.scale(
            scale: 0.8 + 0.4 * t,
            child: Container(
              width: sizes[widget.index],
              height: sizes[widget.index],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: PinColors.greenSuccess.withOpacity(0.15),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Forgot-PIN helper widgets ─────────────────────────

/// Animated envelope icon with red badge (used in step 0).
class EnvelopeIcon extends StatelessWidget {
  final AnimationController breatheController;

  const EnvelopeIcon({super.key, required this.breatheController});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.06).animate(
            CurvedAnimation(parent: breatheController, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFDE8F0), Color(0xFFF0E8FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFDE8F0).withOpacity(0.40),
                  blurRadius: 0,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: PinColors.roseDeep.withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text('📬', style: TextStyle(fontSize: 36)),
            ),
          ),
        ),
        Positioned(
          top: -2,
          right: -4,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: kRoseGradient,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: const Center(
              child: Text(
                '!',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// User-type badge pill: "Guest account" or "Registered account".
class UserTypePill extends StatelessWidget {
  final bool isAnon;

  const UserTypePill({super.key, required this.isAnon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: isAnon
            ? PinColors.roseDeep.withOpacity(0.09)
            : PinColors.greenSuccess.withOpacity(0.09),
        border: Border.all(
          color: isAnon
              ? PinColors.roseDeep.withOpacity(0.20)
              : PinColors.greenSuccess.withOpacity(0.20),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAnon ? '👤 Guest account' : '✓ Registered account',
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: isAnon ? PinColors.roseDeep : PinColors.greenSuccess,
        ),
      ),
    );
  }
}

/// Small trust pill (🔒 Encrypted, etc.).
class TrustPill extends StatelessWidget {
  final String label;

  const TrustPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.68),
        border: Border.all(color: PinColors.peachBorder.withOpacity(0.9)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: PinColors.textHint,
        ),
      ),
    );
  }
}

/// Numbered row inside the "What happens next" card.
class NextStepRow extends StatelessWidget {
  final String num;
  final String text;
  final String bold;
  final String suffix;

  const NextStepRow({
    super.key,
    required this.num,
    required this.text,
    required this.bold,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: kRoseGradient,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PinColors.mutedBrown,
                ),
                children: [
                  TextSpan(text: text),
                  TextSpan(
                    text: bold,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  TextSpan(
                    text: suffix,
                    style: TextStyle(
                      color: PinColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "What happens next" card shown on step 0.
class NextStepsCard extends StatelessWidget {
  const NextStepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        border: Border.all(color: PinColors.peachBorder.withOpacity(0.8)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✦ WHAT HAPPENS NEXT',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: PinColors.textSubtle,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          const NextStepRow(
            num: '1',
            text: 'We send a ',
            bold: '6-digit code',
            suffix: ' to your email (expires in 10 mins)',
          ),
          const NextStepRow(
            num: '2',
            text: 'Enter the code to ',
            bold: 'verify your identity',
          ),
          const NextStepRow(
            num: '3',
            text: 'Create a ',
            bold: 'new PIN',
            suffix: ' and you\'re back in 🌸',
          ),
        ],
      ),
    );
  }
}

// ── Shared screen decorations ─────────────────────────

/// Animated breathing Soluna logo orb.
class SolunaLogoOrb extends StatelessWidget {
  final AnimationController controller;
  final double size;

  const SolunaLogoOrb({
    super.key,
    required this.controller,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFDE8C8), Color(0xFFF0D8F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFDE8C8).withOpacity(0.35),
              spreadRadius: 9,
            ),
            BoxShadow(
              color: PinColors.amberGold.withOpacity(0.22),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: RotationTransition(
          turns: Tween<double>(begin: -0.014, end: 0.014).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
          child: const Center(
            child: Text('🌸', style: TextStyle(fontSize: 38)),
          ),
        ),
      ),
    );
  }
}

/// Sol|una wordmark in amber/rose split colour.
class SolunaWordmark extends StatelessWidget {
  final double fontSize;

  const SolunaWordmark({super.key, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.nunito(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
        children: [
          TextSpan(
            text: 'Sol',
            style: TextStyle(color: PinColors.amberGold),
          ),
          TextSpan(
            text: 'una',
            style: TextStyle(color: PinColors.roseDeep),
          ),
        ],
      ),
    );
  }
}
