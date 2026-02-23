import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pin_constants.dart';
import 'pin_widgets.dart';

// ═══════════════════════════════════════════════════════
//  FORGOT PIN — STEP BODIES
//
//  Each widget renders the scrollable body for one step
//  of the ForgotPinOverlay.  All state callbacks are
//  passed in via constructor so the steps stay pure UI.
// ═══════════════════════════════════════════════════════

// ── Step 0: Email collection (anonymous users only) ───

class ForgotPinStep0Email extends StatelessWidget {
  final AnimationController breatheController;
  final TextEditingController emailController;
  final bool emailDirty;
  final bool emailValid;
  final String emailHint;
  final void Function(String) onEmailChanged;

  const ForgotPinStep0Email({
    super.key,
    required this.breatheController,
    required this.emailController,
    required this.emailDirty,
    required this.emailValid,
    required this.emailHint,
    required this.onEmailChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        children: [
          // Animated envelope icon
          EnvelopeIcon(breatheController: breatheController),
          const SizedBox(height: 14),

          // User type badge
          const UserTypePill(isAnon: true),
          const SizedBox(height: 12),

          // Title
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: PinColors.darkBrown,
              ),
              children: const [
                TextSpan(text: 'Add a '),
                TextSpan(
                  text: 'recovery',
                  style: TextStyle(color: PinColors.amberGold),
                ),
                TextSpan(text: ' email'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          Text(
            "Since you're using a guest account, we don't have your email "
            "on file. Add one now so we can send you a reset code.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PinColors.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // Email text field
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: onEmailChanged,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: PinColors.darkBrown,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  emailDirty ? (emailValid ? '✉️' : '⚠️') : '📧',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              hintText: 'your@email.com',
              hintStyle: GoogleFonts.nunito(
                color: const Color(0xFFDDBEC0),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              suffixIcon: emailValid
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('✅', style: TextStyle(fontSize: 18)),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.85),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    const BorderSide(color: PinColors.peachBorder, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: emailDirty
                      ? (emailValid
                          ? PinColors.greenSuccess
                          : PinColors.errorRed)
                      : PinColors.peachBorder,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color:
                      emailValid ? PinColors.greenSuccess : PinColors.roseDeep,
                  width: 2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
          ),

          // Inline hint
          if (emailHint.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  emailHint,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: emailValid
                        ? PinColors.greenSuccess
                        : PinColors.errorRed,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Trust pills
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              TrustPill(label: '🔒 Encrypted'),
              TrustPill(label: '🚫 No marketing'),
              TrustPill(label: '🗑️ Delete anytime'),
            ],
          ),

          const SizedBox(height: 16),

          // What happens next card
          const NextStepsCard(),
        ],
      ),
    );
  }
}

// ── Step 1: OTP verification ──────────────────────────

class ForgotPinStep1Otp extends StatelessWidget {
  final String displayEmail;
  final List<String> otp;
  final bool otpVerified;
  final String otpMsg;
  final bool otpMsgOk;
  final void Function(String) onKey;
  final VoidCallback onDelete;
  final VoidCallback onResend;

  const ForgotPinStep1Otp({
    super.key,
    required this.displayEmail,
    required this.otp,
    required this.otpVerified,
    required this.otpMsg,
    required this.otpMsgOk,
    required this.onKey,
    required this.onDelete,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        children: [
          const Text('✉️', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 14),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: PinColors.darkBrown,
              ),
              children: const [
                TextSpan(text: 'Check your '),
                TextSpan(
                  text: 'email',
                  style: TextStyle(color: PinColors.amberGold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          Text(
            "We've sent a 6-digit code. It expires in 10 minutes — enter it below.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PinColors.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),

          // Email indicator box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.80),
              border: Border.all(color: PinColors.peachBorder, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text('📧', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CODE SENT TO',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: PinColors.textSubtle,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      displayEmail,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: PinColors.darkBrown,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6-cell OTP display
          OtpCellRow(entered: otp, verified: otpVerified),
          const SizedBox(height: 10),

          // Status message
          if (otpMsg.isNotEmpty)
            Text(
              otpMsg,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: otpMsgOk ? PinColors.greenSuccess : PinColors.errorRed,
              ),
            ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't get it? ",
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: PinColors.textSubtle,
                ),
              ),
              GestureDetector(
                onTap: onResend,
                child: Text(
                  'Resend code',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: PinColors.roseDeep,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          OtpNumpad(
            onKey: onKey,
            onDelete: onDelete,
            disabled: otpVerified,
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Create new PIN ────────────────────────────

class ForgotPinStep2NewPin extends StatelessWidget {
  final List<String> newPin;
  final int pinStrength; // 0–3
  final String strengthLabel;
  final bool weakPinWarning;
  final void Function(String) onKey;
  final VoidCallback onDelete;

  const ForgotPinStep2NewPin({
    super.key,
    required this.newPin,
    required this.pinStrength,
    required this.strengthLabel,
    required this.weakPinWarning,
    required this.onKey,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        children: [
          const Text('🔐', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 14),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: PinColors.darkBrown,
              ),
              children: const [
                TextSpan(text: 'Create a '),
                TextSpan(
                  text: 'new PIN',
                  style: TextStyle(color: PinColors.amberGold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          Text(
            "Choose a 4-digit PIN you'll remember. "
            "Avoid easy ones like 1234 or 0000.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PinColors.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // Simple filled dots (no shake needed here)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < newPin.length;
              return PinDot(
                state: filled ? PinDotState.filled : PinDotState.empty,
              );
            }),
          ),
          const SizedBox(height: 10),

          // Strength bars
          _StrengthBars(strength: pinStrength),
          const SizedBox(height: 4),

          Text(
            strengthLabel,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: [
                PinColors.textSubtle,
                PinColors.errorRed,
                PinColors.warnAmber,
                PinColors.greenSuccess,
              ][pinStrength],
            ),
          ),

          if (weakPinWarning) ...[
            const SizedBox(height: 4),
            Text(
              '⚠️ That PIN is too easy to guess',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PinColors.warnAmber,
              ),
            ),
          ],

          const SizedBox(height: 16),

          OtpNumpad(
            onKey: onKey,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Three animated strength bars — weak / medium / strong.
class _StrengthBars extends StatelessWidget {
  final int strength; // 0–3

  const _StrengthBars({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        Color barColor;
        if (i >= strength) {
          barColor = PinColors.peachBorder;
        } else if (strength == 1) {
          barColor = PinColors.errorRed.withOpacity(0.8);
        } else if (strength == 2) {
          barColor = const Color(0xFFF0C060);
        } else {
          barColor = PinColors.greenLight;
        }
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 56,
          height: 3,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// ── Step 3: Confirm PIN ───────────────────────────────

class ForgotPinStep3Confirm extends StatelessWidget {
  final List<String> confPin;
  final bool isError;
  final bool isSuccess;
  final String confMsg;
  final bool confMsgOk;
  final Animation<double> shakeAnimation;
  final void Function(String) onKey;
  final VoidCallback onDelete;

  const ForgotPinStep3Confirm({
    super.key,
    required this.confPin,
    required this.isError,
    required this.isSuccess,
    required this.confMsg,
    required this.confMsgOk,
    required this.shakeAnimation,
    required this.onKey,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        children: [
          const Text('✅', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 14),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: PinColors.darkBrown,
              ),
              children: const [
                TextSpan(text: 'Confirm your '),
                TextSpan(
                  text: 'PIN',
                  style: TextStyle(color: PinColors.amberGold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'Enter the same 4-digit PIN one more time to make sure we got it right.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PinColors.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // Confirm dots (with shake + colour feedback)
          ForgotPinDotRow(
            filledCount: confPin.length,
            isError: isError,
            isSuccess: isSuccess,
            shakeAnimation: shakeAnimation,
          ),
          const SizedBox(height: 10),

          if (confMsg.isNotEmpty)
            Text(
              confMsg,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: confMsgOk ? PinColors.greenSuccess : PinColors.errorRed,
              ),
            ),

          const SizedBox(height: 16),

          OtpNumpad(
            onKey: onKey,
            onDelete: onDelete,
            disabled: isSuccess,
          ),
        ],
      ),
    );
  }
}

// ── Step 4: Success ───────────────────────────────────

class ForgotPinStep4Success extends StatelessWidget {
  const ForgotPinStep4Success({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        children: [
          // Pulsing rings + celebration emoji
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SuccessRing(index: 0),
                SuccessRing(index: 1),
                SuccessRing(index: 2),
                const Text('🎉', style: TextStyle(fontSize: 44)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'PIN updated!',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: PinColors.darkBrown,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'Your new PIN is set and ready.\nUse it next time you open Soluna. 🌸',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PinColors.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // "What changed" summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PinColors.greenSuccess.withOpacity(0.08),
              border: Border.all(
                color: PinColors.greenSuccess.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✓ WHAT CHANGED',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: PinColors.greenSuccess,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '🔐 New PIN saved locally\n'
                  '☁️ Synced securely to your account\n'
                  '🔄 Failed attempts reset to zero',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PinColors.darkBrown,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
