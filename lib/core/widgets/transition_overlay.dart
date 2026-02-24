// lib/core/widgets/transition_overlay.dart
//
// Usage — wrap any async navigation:
//
//   await TransitionOverlay.show(
//     context,
//     message: 'Setting things up…',
//     future: myAsyncWork(),
//   );
//   if (mounted) context.go('/next-screen');

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class TransitionOverlay extends StatefulWidget {
  final Color themeColor;
  final String message;
  final String? submessage;
  final String emoji;

  const TransitionOverlay._({
    required this.themeColor,
    required this.message,
    this.submessage,
    required this.emoji,
  });

  // ── Static helper: show overlay while a future completes ──────
  static Future<T> show<T>(
    BuildContext context, {
    required Future<T> future,
    String message = 'Just a moment…',
    String? submessage,
    String emoji = '✨',
    Color? themeColor,
  }) async {
    final color = themeColor ?? AppColors.primaryRose;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => TransitionOverlay._(
        themeColor: color,
        message: message,
        submessage: submessage,
        emoji: emoji,
      ),
    );

    try {
      final result = await future;
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      return result;
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      rethrow;
    }
  }

  @override
  State<TransitionOverlay> createState() => _TransitionOverlayState();
}

class _TransitionOverlayState extends State<TransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.88, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fade = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            // Matches the soft gradient card style used throughout the app
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.themeColor.withOpacity(0.18),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Pulsing emoji orb ───────────────────────────
              ScaleTransition(
                scale: _pulse,
                child: FadeTransition(
                  opacity: _fade,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.themeColor.withOpacity(0.18),
                          widget.themeColor.withOpacity(0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Thin progress bar ───────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: widget.themeColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
                ),
              ),

              const SizedBox(height: 20),

              // ── Message ─────────────────────────────────────
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: 0.2,
                ),
              ),

              if (widget.submessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.submessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMid,
                    height: 1.5,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Animated dots (matches DeletionOverlay style) ─
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) {
                      final delay = i * 0.18;
                      final t = (_ctrl.value - delay) % 1.0;
                      final opacity =
                          (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.25, 1.0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.themeColor.withOpacity(opacity),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
