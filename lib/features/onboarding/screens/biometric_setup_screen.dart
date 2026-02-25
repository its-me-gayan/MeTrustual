import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/uuid_persistence_service.dart';
import '../../../core/services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';

// Reuse the exact same widgets & constants as PinVerificationScreen
import 'pin_constants.dart';
import 'pin_widgets.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  final String uid;
  const BiometricSetupScreen({super.key, required this.uid});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen>
    with TickerProviderStateMixin {
  // ── Setup flow state ─────────────────────────────────
  bool _isBiometricAvailable = false;
  bool _isLoading = false;
  bool _pinAlreadyExists = false;

  // ── PIN entry state ───────────────────────────────────
  // _stage: 0 = intro, 1 = enter PIN, 2 = confirm PIN
  int _stage = 0;
  final List<String> _pin = [];
  final List<String> _confirm = [];
  bool _dotsError = false;

  // ── Animation controllers (match PinVerificationScreen) ─
  late AnimationController _logoController;
  late AnimationController _dotShakeCtrl;
  late Animation<double> _dotShakeAnim;

  @override
  void initState() {
    super.initState();
    debugPrint('🔐 BiometricSetupScreen initialized with UID: ${widget.uid}');

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

    _checkBiometricAvailability();
    _checkIfPinExists();
    _persistUUID();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _dotShakeCtrl.dispose();
    super.dispose();
  }

  // ── Init helpers ─────────────────────────────────────

  Future<void> _persistUUID() async {
    await UUIDPersistenceService.saveUUID(widget.uid);
    await UUIDPersistenceService.backupUUIDToCloud(widget.uid);
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await BiometricService.isBiometricAvailable();
    if (mounted) setState(() => _isBiometricAvailable = available);
  }

  Future<void> _checkIfPinExists() async {
    final pinExists = await BiometricService.isBiometricSetUp();
    if (pinExists && mounted) {
      setState(() => _pinAlreadyExists = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.go('/home');
      });
    }
  }

  // ── Numpad callbacks ──────────────────────────────────

  void _onKey(String digit) {
    if (_isLoading) return;

    if (_stage == 1) {
      if (_pin.length >= 4) return;
      setState(() {
        _dotsError = false;
        _pin.add(digit);
      });
      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 120), _advanceToConfirm);
      }
    } else if (_stage == 2) {
      if (_confirm.length >= 4) return;
      setState(() {
        _dotsError = false;
        _confirm.add(digit);
      });
      if (_confirm.length == 4) {
        Future.delayed(const Duration(milliseconds: 120), _savePIN);
      }
    }
  }

  void _onDelete() {
    if (_isLoading) return;
    setState(() {
      _dotsError = false;
      if (_stage == 1 && _pin.isNotEmpty) _pin.removeLast();
      if (_stage == 2 && _confirm.isNotEmpty) _confirm.removeLast();
    });
  }

  // ── Stage transitions ─────────────────────────────────

  void _startPinEntry() {
    setState(() {
      _stage = 1;
      _pin.clear();
      _confirm.clear();
      _dotsError = false;
    });
  }

  void _advanceToConfirm() {
    if (!mounted) return;
    setState(() {
      _stage = 2;
      _confirm.clear();
      _dotsError = false;
    });
  }

  Future<void> _savePIN() async {
    if (_pin.join() != _confirm.join()) {
      // PINs don't match — shake dots, reset confirm
      setState(() => _dotsError = true);
      _dotShakeCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _dotsError = false;
          _stage = 2;
          _confirm.clear();
        });
        NotificationService.showError(context, 'PINs do not match — try again');
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await BiometricService.setBiometricPin(_pin.join());
      if (success) {
        if (mounted) context.go('/home');
      } else {
        if (mounted)
          NotificationService.showError(context, 'Failed to save PIN');
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Already has a PIN — show redirect spinner
    if (_pinAlreadyExists) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF0F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        constraints:
            BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        decoration: const BoxDecoration(gradient: kPinBackgroundGradient),
        child: Stack(
          children: [
            // ── Ambient glow orbs (identical to PinVerificationScreen) ──
            Positioned(
              top: -80,
              right: -80,
              child: GlowOrb(
                  size: 320, color: const Color(0xFFE8A84A), opacity: 0.07),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child:
                  GlowOrb(size: 280, color: PinColors.roseDeep, opacity: 0.08),
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

            // ── Main content ──
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 52),

                    // Logo orb — same breathing animation
                    SolunaLogoOrb(controller: _logoController),
                    const SizedBox(height: 14),

                    SolunaWordmark(),
                    const SizedBox(height: 4),

                    // Subtitle changes per stage
                    Text(
                      _stage == 0
                          ? 'Protect your health data 🔒'
                          : _stage == 1
                              ? 'Choose a 4-digit PIN'
                              : 'Confirm your PIN',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PinColors.textHint,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Stage 0: Intro card ─────────────────────────
                    if (_stage == 0) _buildIntroCard(),

                    // ── Stage 1 & 2: Dots + numpad ─────────────────
                    if (_stage >= 1) ...[
                      PinDotRow(
                        filledCount:
                            _stage == 1 ? _pin.length : _confirm.length,
                        isError: _dotsError,
                        shakeAnimation: _dotShakeAnim,
                      ),
                      const SizedBox(height: 4),

                      // Status hint
                      SizedBox(
                        height: 22,
                        child: Text(
                          _stage == 1
                              ? 'Enter 4 digits'
                              : 'Re-enter to confirm',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: PinColors.textHint,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Numpad — identical layout to PinVerificationScreen
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                        child: PinNumpad(
                          onKey: _onKey,
                          onDelete: _onDelete,
                          onBiometric: null, // not needed during setup
                          disabled: _isLoading,
                        ),
                      ),

                      // Back to previous stage
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => setState(() {
                                  if (_stage == 2) {
                                    _stage = 1;
                                    _confirm.clear();
                                    _dotsError = false;
                                  } else {
                                    _stage = 0;
                                    _pin.clear();
                                    _dotsError = false;
                                  }
                                }),
                        child: Text(
                          '← Back',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: PinColors.textSubtle,
                            decoration: TextDecoration.underline,
                            decorationColor: PinColors.textSubtle,
                            decorationThickness: 1.2,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── Saving overlay ──
            if (_isLoading) const _SavingOverlay(),
          ],
        ),
      ),
    );
  }

  // ── Intro card (stage 0) ──────────────────────────────
  Widget _buildIntroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          // Feature rows
          _buildFeatureRow('🔒', 'PIN protects your health data'),
          const SizedBox(height: 10),
          _buildFeatureRow('🧬', 'Only you can unlock this app'),
          const SizedBox(height: 10),
          if (_isBiometricAvailable)
            _buildFeatureRow('🪪', 'Face ID / biometrics supported'),
          const SizedBox(height: 32),

          // CTA button — full width, same style as rest of app
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRose.withOpacity(0.35),
                  offset: const Offset(0, 6),
                  blurRadius: 18,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _startPinEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                _isBiometricAvailable ? 'Set up PIN & Biometric' : 'Set up PIN',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Recommended · Takes less than 1 minute',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: PinColors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Text(
              'Skip for now',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: PinColors.textSubtle,
                decoration: TextDecoration.underline,
                decorationColor: PinColors.textSubtle,
                decorationThickness: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: PinColors.roseDeep.withOpacity(0.12), width: 1.5),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PinColors.darkBrown,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SAVING OVERLAY  (same pattern as _VerifyingOverlay)
// ─────────────────────────────────────────────────────────
class _SavingOverlay extends StatelessWidget {
  const _SavingOverlay();

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
                'Saving your PIN…',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: PinColors.darkBrown,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Almost there 🔐',
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
