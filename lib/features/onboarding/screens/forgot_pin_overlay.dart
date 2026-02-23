import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/biometric_service.dart';
import 'pin_constants.dart';
import 'pin_widgets.dart';
import 'forgot_pin_steps.dart';

// ═══════════════════════════════════════════════════════
//  FORGOT PIN OVERLAY
//
//  A bottom-sheet overlay that guides the user through
//  resetting their PIN in up to 5 steps:
//
//    Step 0  — Email collection  (anonymous users only)
//    Step 1  — OTP verification
//    Step 2  — Create new PIN
//    Step 3  — Confirm new PIN
//    Step 4  — Success
//
//  Usage:
//    showModalBottomSheet(
//      context: context,
//      isScrollControlled: true,
//      backgroundColor: Colors.transparent,
//      useRootNavigator: true,
//      builder: (_) => ForgotPinOverlay(
//        isAnonymous: true,
//        knownEmail: null,            // pass for registered users
//      ),
//    );
// ═══════════════════════════════════════════════════════

class ForgotPinOverlay extends StatefulWidget {
  final bool isAnonymous;
  final String? knownEmail;

  const ForgotPinOverlay({
    super.key,
    required this.isAnonymous,
    this.knownEmail,
  });

  @override
  State<ForgotPinOverlay> createState() => _ForgotPinOverlayState();
}

class _ForgotPinOverlayState extends State<ForgotPinOverlay>
    with TickerProviderStateMixin {
  // ── Step index ─────────────────────────────────────
  // 0=email collect (anon only), 1=OTP, 2=newPIN, 3=confirm, 4=success
  late int _step;
  bool _isLoading = false;

  // ── Step 0 — email collection ──────────────────────
  final _emailController = TextEditingController();
  String _emailHint = '';
  bool _emailValid = false;
  bool _emailDirty = false;
  String _collectedEmail = '';

  // ── Step 1 — OTP ───────────────────────────────────
  final List<String> _otp = [];
  String _otpMsg = '';
  bool _otpMsgOk = false;
  bool _otpVerified = false;
  // TODO: replace with real 6-digit OTP from Cloud Function
  static const String _demoOtp = '123456';

  // ── Step 2 — new PIN ───────────────────────────────
  final List<String> _newPin = [];
  int _pinStrength = 0;
  String _strengthLabel = 'Enter your new PIN';
  bool _newPinWeakWarn = false;

  // ── Step 3 — confirm PIN ───────────────────────────
  final List<String> _confPin = [];
  String _confMsg = '';
  bool _confMsgOk = false;
  bool _confDotsError = false;
  bool _confDotsSuccess = false;

  // ── Animation controllers ──────────────────────────
  late AnimationController _breatheCtrl;
  late AnimationController _dotShakeCtrl;
  late Animation<double> _dotShakeAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _dotShakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _dotShakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dotShakeCtrl, curve: Curves.elasticIn),
    );

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _step = widget.isAnonymous ? 0 : 1;
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _breatheCtrl.dispose();
    _dotShakeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  //  NAVIGATION
  // ─────────────────────────────────────────────────────

  void _goStep(int next) {
    setState(() => _step = next);
    _slideCtrl.forward(from: 0);
  }

  void _goBack() {
    if (_step <= (widget.isAnonymous ? 0 : 1)) {
      Navigator.pop(context);
      return;
    }
    final prev = _step - 1;
    if (prev == 2)
      setState(() {
        _confPin.clear();
        _confMsg = '';
      });
    if (prev == 1) {
      setState(() {
        _otp.clear();
        _otpMsg = '';
        _otpVerified = false;
      });
    }
    _goStep(prev);
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _emailValid;
      case 1:
        return _otpVerified;
      case 2:
        return _newPin.length == 4;
      case 3:
        return _confPin.length == 4 && _confDotsSuccess;
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _onContinue() {
    switch (_step) {
      case 0:
        _submitEmail();
        break;
      case 1:
        if (_otpVerified) _goStep(2);
        break;
      case 2:
        if (_newPin.length == 4) _goStep(3);
        break;
      case 3:
        if (_confDotsSuccess) _goStep(4);
        break;
      case 4:
        Navigator.pop(context);
        break;
    }
  }

  // ─────────────────────────────────────────────────────
  //  STEP 0 — email
  // ─────────────────────────────────────────────────────

  void _onEmailChanged(String val) {
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(val.trim());
    setState(() {
      _emailDirty = val.isNotEmpty;
      _emailValid = valid;
      _emailHint = val.isEmpty
          ? ''
          : valid
              ? '✓ Looks good — we\'ll send your code here'
              : 'Please enter a valid email address (e.g. you@example.com)';
    });
  }

  Future<void> _submitEmail() async {
    if (!_emailValid) return;
    setState(() => _isLoading = true);

    // TODO: replace with real Cloud Function call to send OTP
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _collectedEmail = _emailController.text.trim();
    });
    _goStep(1);
  }

  // ─────────────────────────────────────────────────────
  //  STEP 1 — OTP
  // ─────────────────────────────────────────────────────

  void _otpKey(String d) {
    if (_otp.length >= 6 || _otpVerified) return;
    setState(() => _otp.add(d));
    if (_otp.length == 6) {
      Future.delayed(const Duration(milliseconds: 120), _verifyOtp);
    }
  }

  void _otpDelete() {
    if (_otp.isEmpty) return;
    setState(() {
      _otp.removeLast();
      _otpMsg = '';
    });
  }

  void _verifyOtp() {
    if (_otp.join() == _demoOtp) {
      setState(() {
        _otpMsg = '✓ Code verified!';
        _otpMsgOk = true;
        _otpVerified = true;
      });
    } else {
      setState(() {
        _otpMsg = '⚠️ Incorrect code. Try again.';
        _otpMsgOk = false;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted)
          setState(() {
            _otp.clear();
            _otpMsg = '';
          });
      });
    }
  }

  void _resendOtp() {
    setState(() {
      _otp.clear();
      _otpMsg = '✉️ New code sent!';
      _otpMsgOk = true;
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _otpMsg = '');
    });
  }

  // ─────────────────────────────────────────────────────
  //  STEP 2 — new PIN
  // ─────────────────────────────────────────────────────

  void _newPinKey(String d) {
    if (_newPin.length >= 4) return;
    setState(() => _newPin.add(d));
    _updateStrength();
    if (_newPin.length == 4) _checkWeakPin();
  }

  void _newPinDelete() {
    if (_newPin.isEmpty) return;
    setState(() {
      _newPin.removeLast();
      _newPinWeakWarn = false;
    });
    _updateStrength();
  }

  void _updateStrength() {
    final pin = _newPin.join();
    int s = 0;
    if (pin.length >= 4) s = 1;
    if (pin.length >= 4 && pin.split('').toSet().length >= 3) s = 2;
    if (pin.length >= 4 && pin.split('').toSet().length >= 4) s = 3;
    if (kWeakPins.contains(pin)) s = 1;

    const labels = [
      'Enter your new PIN',
      'Weak PIN — try something harder',
      'Medium — looking better!',
      'Strong PIN 💪',
    ];
    setState(() {
      _pinStrength = s;
      _strengthLabel = labels[s];
    });
  }

  void _checkWeakPin() {
    setState(() => _newPinWeakWarn = kWeakPins.contains(_newPin.join()));
  }

  // ─────────────────────────────────────────────────────
  //  STEP 3 — confirm PIN
  // ─────────────────────────────────────────────────────

  void _confKey(String d) {
    if (_confPin.length >= 4 || _confDotsSuccess) return;
    setState(() => _confPin.add(d));
    if (_confPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _checkConfirm);
    }
  }

  void _confDelete() {
    if (_confPin.isEmpty) return;
    setState(() {
      _confPin.removeLast();
      _confMsg = '';
    });
  }

  void _checkConfirm() {
    if (_newPin.join() == _confPin.join()) {
      setState(() {
        _confMsg = '✓ PINs match!';
        _confMsgOk = true;
        _confDotsSuccess = true;
        _confDotsError = false;
      });
    } else {
      setState(() {
        _confMsg = '⚠️ PINs don\'t match. Try again.';
        _confMsgOk = false;
        _confDotsError = true;
      });
      _dotShakeCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            _confPin.clear();
            _confMsg = '';
            _confDotsError = false;
          });
        }
      });
    }
  }

  // ─────────────────────────────────────────────────────
  //  STEP 4 — save
  // ─────────────────────────────────────────────────────

  Future<void> _saveNewPin() async {
    try {
      await BiometricService.setBiometricPin(_newPin.join());
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────

  String _maskEmail(String email) {
    if (email.isEmpty) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.isEmpty) return email;
    final visible = local[0];
    final masked = local.length <= 2
        ? '$visible***'
        : '$visible${'*' * math.min(local.length - 2, 4)}${local[local.length - 1]}';
    return '$masked@$domain';
  }

  // ─────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Trigger PIN save when step 4 is first shown
    if (_step == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _saveNewPin());
    }

    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.92,
      decoration: const BoxDecoration(
        gradient: kPinBackgroundGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Drag handle ──
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: PinColors.roseDeep.withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),

          // ── Header (back button + title + step label) ──
          _buildHeader(),

          // ── Progress bar ──
          _buildProgressBar(),

          // ── Step body (fades + slides in) ──
          Expanded(
            child: FadeTransition(
              opacity: _slideCtrl,
              child: SlideTransition(
                position: _slideAnim,
                child: _buildStepBody(),
              ),
            ),
          ),

          // ── Footer CTA ──
          _buildFooter(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  SUB-BUILDERS
  // ─────────────────────────────────────────────────────

  Widget _buildHeader() {
    final titles = [
      'Forgot PIN',
      'Check Your Email',
      'Create New PIN',
      'Confirm PIN',
      'PIN Updated',
    ];
    final stepLabel = _buildStepLabel();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Back button (hidden on success)
          if (_step < 4)
            GestureDetector(
              onTap: _goBack,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: PinColors.roseDeep.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: PinColors.textHint,
                ),
              ),
            )
          else
            const SizedBox(width: 34),

          // Title + step label
          Expanded(
            child: Column(
              children: [
                Text(
                  titles[_step.clamp(0, 4)],
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: PinColors.darkBrown,
                  ),
                ),
                if (stepLabel.isNotEmpty)
                  Text(
                    stepLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: PinColors.textSubtle,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 34), // spacer to balance back button
        ],
      ),
    );
  }

  String _buildStepLabel() {
    if (_step == 0 || _step == 4) return '';
    final total = widget.isAnonymous ? 4 : 3;
    final num = widget.isAnonymous ? _step + 1 : _step;
    return 'Step $num of $total';
  }

  Widget _buildProgressBar() {
    final total = widget.isAnonymous ? 4 : 3;
    final num = widget.isAnonymous ? _step + 1 : _step;
    final pct = _step == 4 ? 1.0 : (num / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: PinColors.peachBorder,
          valueColor: const AlwaysStoppedAnimation<Color>(PinColors.roseDeep),
          minHeight: 3,
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return ForgotPinStep0Email(
          breatheController: _breatheCtrl,
          emailController: _emailController,
          emailDirty: _emailDirty,
          emailValid: _emailValid,
          emailHint: _emailHint,
          onEmailChanged: _onEmailChanged,
        );

      case 1:
        final displayEmail = widget.isAnonymous
            ? _maskEmail(_collectedEmail)
            : (widget.knownEmail ?? '');
        return ForgotPinStep1Otp(
          displayEmail: displayEmail,
          otp: _otp,
          otpVerified: _otpVerified,
          otpMsg: _otpMsg,
          otpMsgOk: _otpMsgOk,
          onKey: _otpKey,
          onDelete: _otpDelete,
          onResend: _resendOtp,
        );

      case 2:
        return ForgotPinStep2NewPin(
          newPin: _newPin,
          pinStrength: _pinStrength,
          strengthLabel: _strengthLabel,
          weakPinWarning: _newPinWeakWarn,
          onKey: _newPinKey,
          onDelete: _newPinDelete,
        );

      case 3:
        return ForgotPinStep3Confirm(
          confPin: _confPin,
          isError: _confDotsError,
          isSuccess: _confDotsSuccess,
          confMsg: _confMsg,
          confMsgOk: _confMsgOk,
          shakeAnimation: _dotShakeAnim,
          onKey: _confKey,
          onDelete: _confDelete,
        );

      case 4:
        return const ForgotPinStep4Success();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFooter() {
    const labels = [
      'Send Reset Code 📬',
      'Verify Code →',
      'Continue →',
      'Set New PIN ✓',
      'Back to unlock →',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            gradient: _canContinue && !_isLoading ? kRoseGradient : null,
            color: _canContinue && !_isLoading ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: _canContinue
                ? null
                : Border.all(
                    color: PinColors.roseDeep.withOpacity(0.3),
                    width: 1.5,
                  ),
            boxShadow: _canContinue
                ? [
                    BoxShadow(
                      color: PinColors.roseDeep.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    )
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: (_canContinue && !_isLoading) ? _onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(PinColors.roseDeep),
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    labels[_step.clamp(0, 4)],
                    style: GoogleFonts.nunito(
                      color: _canContinue ? Colors.white : PinColors.roseDeep,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
