import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/premium_provider.dart';
import '../providers/mode_provider.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wraps any widget with a premium gate.
/// - [isOverlay] = true  → blurs child and shows an unlock pill on top
/// - [isOverlay] = false → replaces child with a locked card
/// Nothing here changes; tapping still routes to '/premium' which now
/// renders [PremiumScreen].
class PremiumGate extends ConsumerWidget {
  final Widget child;
  final String? message;
  final bool isOverlay;

  const PremiumGate({
    super.key,
    required this.child,
    this.message,
    this.isOverlay = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumStatusProvider).value ?? false;
    final currentMode = ref.watch(modeProvider);
    final themeColor = AppColors.getModeColor(currentMode, soft: true);

    // ── Already premium — render child as-is ──────────────────
    if (isPremium) return child;

    // ── Non-overlay (card replacement) mode ───────────────────
    if (!isOverlay) {
      return GestureDetector(
        onTap: () => context.push('/premium'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: themeColor, size: 32),
              const SizedBox(height: 8),
              Text(
                message ?? 'Unlock with Premium',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800, color: AppColors.textMid),
              ),
            ],
          ),
        ),
      );
    }

    // ── Overlay mode (default) ─────────────────────────────────
    return Stack(
      children: [
        Opacity(opacity: 0.3, child: AbsorbPointer(child: child)),
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              onTap: () => context.push('/premium'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      message ?? 'Unlock Premium',
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
