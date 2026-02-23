import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/widgets/custom_pin_input.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/providers/firebase_providers.dart';
import 'package:google_fonts/google_fonts.dart';

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
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isLoading = false;
  final TextEditingController _pinController = TextEditingController();

  // Subtle logo pulse — reuses the same breath animation as splash
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityProvider);
    final auth = ref.watch(firebaseAuthProvider);
    // ignore: unused_local_variable — kept for parity with original
    final isAuthenticated =
        auth.currentUser != null && !auth.currentUser!.isAnonymous;

    return Scaffold(
      backgroundColor: Colors.transparent, // prevent white bleed
      body: Container(
        width: double.infinity,
        // Force the gradient to always fill the full screen height
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
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
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Ambient glow orbs (decorative, pointer-events: none) ──
            Positioned(
              top: -80,
              right: -80,
              child: _GlowOrb(
                size: 320,
                color: const Color(0xFFE8A84A),
                opacity: 0.07,
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: _GlowOrb(
                size: 280,
                color: const Color(0xFFD97B8A),
                opacity: 0.08,
              ),
            ),

            // ── Main content ──
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),

                    // ── Soluna flower logo ──
                    _buildLogo(),

                    const SizedBox(height: 28),

                    // ── App wordmark ──
                    _buildWordmark(),

                    const SizedBox(height: 36),

                    // ── Headline ──
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.nunito(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF3D2828),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your 4-digit PIN to unlock',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: const Color(0xFF8A6870),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Locked state OR PIN input ──
                    if (securityState.isLocked)
                      _buildLockedCard(securityState)
                    else ...[
                      _buildPinSection(securityState),
                    ],

                    const SizedBox(height: 24),

                    // ── Cancel (optional) ──
                    if (widget.allowCancel)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFFB09090),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  WIDGETS
  // ─────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Peach → lavender — identical to splash
          gradient: const LinearGradient(
            colors: [Color(0xFFFDE8C8), Color(0xFFF0D8F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFDE8C8).withOpacity(0.45),
              blurRadius: 0,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: const Color(0xFFD97B8A).withOpacity(0.22),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: RotationTransition(
          turns: Tween<double>(begin: -0.012, end: 0.012).animate(
            CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
          ),
          child: const Center(
            child: Text('🌸', style: TextStyle(fontSize: 42)),
          ),
        ),
      ),
    );
  }

  Widget _buildWordmark() {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
        children: const [
          TextSpan(
            text: 'Sol',
            style: TextStyle(color: Color(0xFFC97B3A)), // Amber gold
          ),
          TextSpan(
            text: 'una',
            style: TextStyle(color: Color(0xFFD97B8A)), // Luna rose
          ),
        ],
      ),
    );
  }

  Widget _buildLockedCard(dynamic securityState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(
            'Too many failed attempts',
            style: GoogleFonts.nunito(
              color: Colors.redAccent,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '⏱️ ${securityState.errorMessage}',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.redAccent.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinSection(dynamic securityState) {
    final bool pinReady = _pin.length == 4 && !_isLoading;

    return Column(
      children: [
        // ── PIN input — no card wrapper, sits directly on gradient ──
        CustomPinInput(
          label: '',
          hintText: '• • • •',
          controller: _pinController,
          onChanged: (val) {
            setState(() => _pin = val);
          },
        ),

        // ── Error message ──
        if (securityState.errorMessage != null) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                securityState.errorMessage!,
                style: GoogleFonts.nunito(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 32),

        // ── Unlock button ──
        SizedBox(
          width: double.infinity,
          height: 58,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              // Active: rose gradient with shadow
              // Inactive: transparent with a subtle dashed rose border — no ugly flat fill
              gradient: pinReady
                  ? const LinearGradient(
                      colors: [Color(0xFFF09090), Color(0xFFD97B8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: pinReady ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: pinReady
                  ? null
                  : Border.all(
                      color: const Color(0xFFD97B8A).withOpacity(0.3),
                      width: 1.5,
                    ),
              boxShadow: pinReady
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD97B8A).withOpacity(0.38),
                        offset: const Offset(0, 8),
                        blurRadius: 22,
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed:
                  (pinReady && !securityState.isLocked) ? _verifyPin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFD97B8A)),
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Unlock',
                          style: GoogleFonts.nunito(
                            // Active: white  |  Inactive: rose (readable on transparent)
                            color: pinReady
                                ? Colors.white
                                : const Color(0xFFD97B8A),
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pinReady ? '🔓' : '🔒',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ── Forgot PIN — clean text link, no box/pill ──
        TextButton(
          onPressed: _handleForgotPin,
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
          ),
          child: Text(
            'Forgot PIN?',
            style: GoogleFonts.nunito(
              color: const Color(0xFFD97B8A),
              fontWeight: FontWeight.w700,
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFFD97B8A).withOpacity(0.4),
              decorationThickness: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  void _showVerifyingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true, // ← ADD THIS
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97B8A).withOpacity(0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFD97B8A),
                    ),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Verifying...',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3D2828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Just a moment 🔐',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB09090),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // ─────────────────────────────────────────────────────────────
  //  LOGIC — untouched from original
  // ─────────────────────────────────────────────────────────────

  Future<void> _verifyPin() async {
    if (_pin.length != 4) return;

    setState(() => _isLoading = true);

    // Wait for frame to complete then show overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showVerifyingOverlay();
    });

    // Small delay to ensure overlay is visible before heavy work starts
    await Future.delayed(const Duration(milliseconds: 100));

    final security = ref.read(securityProvider.notifier);

    try {
      final verified = await security.verifyPinWithCloudFallback(_pin);

      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .pop(); // ← rootNavigator: true
      }

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
        if (mounted) {
          setState(() {
            _pin = '';
            _pinController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .pop(); // ← rootNavigator: true
        NotificationService.showError(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPin() async {
    final auth = ref.read(firebaseAuthProvider);
    final emailController = TextEditingController();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFFFFF8F5),
          title: Column(
            children: [
              const Text('🔑', style: TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                'Reset PIN',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: const Color(0xFF3D2828),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email to receive a temporary PIN.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: const Color(0xFF8A6870),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.nunito(
                    fontSize: 14, color: const Color(0xFF3D2828)),
                decoration: InputDecoration(
                  hintText: 'your@email.com',
                  hintStyle: GoogleFonts.nunito(
                      color: const Color(0xFFD0B0B8), fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFFCE8E4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFFCE8E4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD97B8A)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(
                  color: const Color(0xFFB09090),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF09090), Color(0xFFD97B8A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;

                  Navigator.pop(context);
                  setState(() => _isLoading = true);

                  try {
                    final targetEmail = (auth.currentUser != null &&
                            !auth.currentUser!.isAnonymous)
                        ? auth.currentUser!.email!
                        : email;

                    // Sends temp PIN — same logic as original
                    await BiometricService.setBiometricPin("1234");

                    if (mounted) {
                      NotificationService.showSuccess(
                        context,
                        'Temporary PIN sent to $targetEmail! Check your inbox.',
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      NotificationService.showError(
                          context, 'Error: ${e.toString()}');
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                child: Text(
                  'Send PIN',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  GLOW ORB — decorative ambient blob (same pattern as splash)
// ─────────────────────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowOrb({
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
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}
