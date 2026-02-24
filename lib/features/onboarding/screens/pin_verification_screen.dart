import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/services/notification_service.dart';
import 'pin_constants.dart';
import 'pin_widgets.dart';
import 'forgot_pin_overlay.dart';

// ═══════════════════════════════════════════════════════
//  PIN VERIFICATION SCREEN
// ═══════════════════════════════════════════════════════

class PinVerificationScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final bool allowCancel;

  const PinVerificationScreen({
    super.key,
    this.onSuccess,
    this.allowCancel = false,
  });

  @override
  ConsumerState<PinVerificationScreen> createState() =>
      _PinVerificationScreenState();
}

class _PinVerificationScreenState extends ConsumerState<PinVerificationScreen>
    with TickerProviderStateMixin {
  // ── PIN state ────────────────────────────────────────
  final List<String> _entered = [];
  bool _isLoading = false;
  bool _dotsError = false;

  // ── Lockout countdown ────────────────────────────────
  // Timer exists ONLY to call setState() every second so build()
  // re-computes the remaining time from securityState.lockUntil.
  // We never store a separate _remainingTime — that caused the
  // async race where it was always Duration.zero on first render.
  Timer? _lockoutTimer;

  // ── Animation controllers ────────────────────────────
  late AnimationController _logoController;
  late AnimationController _dotShakeCtrl;
  late Animation<double> _dotShakeAnim;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _dotShakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _dotShakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dotShakeCtrl, curve: Curves.elasticIn),
    );

    // Kick off the tick timer after the first frame.
    // It's harmless when not locked — _ensureTimer manages lifecycle.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTimer());
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _logoController.dispose();
    _dotShakeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  //  TIMER — only triggers rebuilds; build() owns the math
  // ─────────────────────────────────────────────────────

  /// Start the 1-second rebuild ticker if not already running.
  /// Safe to call multiple times — no-ops if already active.
  void _ensureTimer() {
    if (_lockoutTimer?.isActive ?? false) return;
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _lockoutTimer?.cancel();
        return;
      }
      final security = ref.read(securityProvider);
      // If lockout has expired, tell the notifier and stop ticking.
      if (security.isLocked &&
          security.lockUntil != null &&
          DateTime.now().isAfter(security.lockUntil!)) {
        ref.read(securityProvider.notifier).checkLockoutExpiry();
        _lockoutTimer?.cancel();
      }
      // Always rebuild so the countdown display stays live.
      setState(() {});
    });
  }

  // ─────────────────────────────────────────────────────
  //  INPUT HANDLERS
  // ─────────────────────────────────────────────────────

  void _onKey(String digit) {
    final security = ref.read(securityProvider);
    if (security.isLocked || _isLoading) return;
    if (_entered.length >= 4) return;

    setState(() {
      _dotsError = false;
      _entered.add(digit);
    });

    if (_entered.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _verifyPin);
    }
  }

  void _onDelete() {
    if (_entered.isEmpty || _isLoading) return;
    setState(() {
      _dotsError = false;
      _entered.removeLast();
    });
  }

  void _onBiometric() {
    // TODO: hook into BiometricService when ready
  }

  // ─────────────────────────────────────────────────────
  //  VERIFY PIN
  // ─────────────────────────────────────────────────────

  Future<void> _verifyPin() async {
    final pinStr = _entered.join();
    if (pinStr.length != 4) return;

    setState(() => _isLoading = true);
    final security = ref.read(securityProvider.notifier);

    try {
      final verified = await security.verifyPinWithCloudFallback(pinStr);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (verified) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            context.go('/home');
          }
        }
      } else {
        setState(() => _dotsError = true);
        _dotShakeCtrl.forward(from: 0);
        // Start ticker in case this attempt triggered a lockout.
        _ensureTimer();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _entered.clear();
            _dotsError = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _entered.clear();
        });
        NotificationService.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  // ─────────────────────────────────────────────────────
  //  FORGOT PIN
  // ─────────────────────────────────────────────────────

  void _handleForgotPin() {
    final security = ref.read(securityProvider);
    if (security.isLocked) return;

    final auth = ref.read(firebaseAuthProvider);
    final isAnonymous =
        auth.currentUser == null || auth.currentUser!.isAnonymous;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => ForgotPinOverlay(
        isAnonymous: isAnonymous,
        knownEmail: isAnonymous ? null : auth.currentUser?.email,
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityProvider);

    // When init finishes and we're locked, ensure the ticker is running.
    // ref.listen is the right hook — fires exactly on the transition.
    ref.listen<SecurityState>(securityProvider, (previous, next) {
      if ((previous?.isInitializing ?? true) && !next.isInitializing) {
        // Init just completed — start ticker regardless of lock state
        // so the first locked-in render is never stale.
        _ensureTimer();
      }
    });

    // Block UI until lockout state is fully restored from storage.
    if (securityState.isInitializing) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF0F5),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4849A)),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final isLocked = securityState.isLocked;

    // ── Compute remaining time HERE, not in async state ──────────────
    // This is the critical fix: every build() call reads lockUntil
    // fresh and computes the remaining duration on the spot.
    // The 1-second timer above calls setState() to keep builds ticking.
    Duration remaining = Duration.zero;
    if (isLocked && securityState.lockUntil != null) {
      final diff = securityState.lockUntil!.difference(DateTime.now());
      remaining = diff.isNegative ? Duration.zero : diff;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        decoration: const BoxDecoration(gradient: kPinBackgroundGradient),
        child: Stack(
          children: [
            // ── Ambient glow orbs ──
            Positioned(
              top: -80,
              right: -80,
              child: GlowOrb(
                size: 320,
                color: const Color(0xFFE8A84A),
                opacity: 0.07,
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: GlowOrb(
                size: 280,
                color: PinColors.roseDeep,
                opacity: 0.08,
              ),
            ),

            // ── Floating petals ──
            FloatingPetal(
              config: PetalConfig(
                  left: 0.08,
                  emoji: '🌸',
                  size: 16,
                  duration: 5200,
                  delay: 300),
            ),
            FloatingPetal(
              config: PetalConfig(
                  left: 0.25,
                  emoji: '✿',
                  size: 13,
                  duration: 6100,
                  delay: 1400),
            ),
            FloatingPetal(
              config: PetalConfig(
                  left: 0.60,
                  emoji: '🌸',
                  size: 18,
                  duration: 4800,
                  delay: 800),
            ),
            FloatingPetal(
              config: PetalConfig(
                  left: 0.82,
                  emoji: '✾',
                  size: 12,
                  duration: 5700,
                  delay: 2000),
            ),

            // ── Main scrollable content ──
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 52),

                    SolunaLogoOrb(controller: _logoController),
                    const SizedBox(height: 14),

                    const SolunaWordmark(),
                    const SizedBox(height: 4),

                    Text(
                      isLocked
                          ? 'Account temporarily locked'
                          : 'Enter your 4-digit PIN to unlock',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PinColors.textHint,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Lockout box — receives live-computed remaining
                    if (isLocked) _LockoutBox(remaining: remaining),

                    // PIN dots
                    PinDotRow(
                      filledCount: _entered.length,
                      isError: _dotsError,
                      shakeAnimation: _dotShakeAnim,
                    ),

                    const SizedBox(height: 4),

                    _StatusMessage(securityState: securityState),

                    const SizedBox(height: 20),

                    // Numpad
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 80),
                      child: PinNumpad(
                        onKey: _onKey,
                        onDelete: _onDelete,
                        onBiometric: _onBiometric,
                        disabled: isLocked || _isLoading,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Tooltip(
                      message: isLocked
                          ? 'Available again once the lockout expires'
                          : '',
                      triggerMode: isLocked
                          ? TooltipTriggerMode.tap
                          : TooltipTriggerMode.manual,
                      preferBelow: false,
                      decoration: BoxDecoration(
                        color: PinColors.errorRed.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      child: GestureDetector(
                        onTap: isLocked ? null : _handleForgotPin,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isLocked ? 0.35 : 1.0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLocked) ...[
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 12,
                                  color: PinColors.textSubtle,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                'Forgot PIN?',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: PinColors.textSubtle,
                                  decoration: TextDecoration.underline,
                                  decorationColor: isLocked
                                      ? PinColors.textSubtle.withOpacity(0.3)
                                      : PinColors.textSubtle,
                                  decorationThickness: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (widget.allowCancel) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.nunito(
                            color: PinColors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── Verifying overlay ──
            if (_isLoading) const _VerifyingOverlay(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PRIVATE SCREEN-LOCAL WIDGETS
// ═══════════════════════════════════════════════════════

class _LockoutBox extends StatelessWidget {
  final Duration remaining;
  const _LockoutBox({required this.remaining});

  String get _timerLabel {
    final mins = remaining.inMinutes;
    final secs = remaining.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0).withOpacity(0.85),
          border: Border.all(color: PinColors.errorRed.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('🔒', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              'Too many attempts',
              style: GoogleFonts.nunito(
                color: PinColors.errorRed,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: PinColors.errorRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: PinColors.errorRed.withOpacity(0.15), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 14, color: PinColors.errorRed.withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Text(
                    'Unlocks in  $_timerLabel',
                    style: GoogleFonts.nunito(
                      color: PinColors.errorRed,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 11, color: PinColors.errorRed.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  'PIN recovery unavailable during lockout',
                  style: GoogleFonts.nunito(
                    color: PinColors.errorRed.withOpacity(0.5),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final SecurityState securityState;
  const _StatusMessage({required this.securityState});

  @override
  Widget build(BuildContext context) {
    final msg = securityState.errorMessage;
    if (msg == null || securityState.isLocked) {
      return const SizedBox(height: 22);
    }
    return SizedBox(
      height: 22,
      child: Text(
        '⚠️ $msg',
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: PinColors.errorRed,
        ),
      ),
    );
  }
}

class _VerifyingOverlay extends StatelessWidget {
  const _VerifyingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: PinColors.roseDeep.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(PinColors.roseDeep),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Verifying...',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: PinColors.darkBrown,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Just a moment 🔐',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PinColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
