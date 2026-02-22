import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/widgets/custom_pin_input.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/providers/firebase_providers.dart';

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

class _PinVerificationScreenState extends ConsumerState<PinVerificationScreen> {
  String _pin = '';
  bool _isLoading = false;
  bool _showForgotOption = false;

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityProvider);
    final auth = ref.watch(firebaseAuthProvider);
    final isAuthenticated = auth.currentUser != null && !auth.currentUser!.isAnonymous;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRose.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🔐', style: TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Unlock Account',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter your 4-digit PIN to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),
              if (securityState.isLocked)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('Too many failed attempts', 
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        '⏱️ ${securityState.errorMessage}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                CustomPinInput(
                  label: '',
                  hintText: '• • • •',
                  onChanged: (val) {
                    setState(() => _pin = val);
                    if (val.length == 4) {
                      _verifyPin();
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (securityState.errorMessage != null)
                  Text(
                    securityState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: (_pin.length == 4 && !_isLoading) 
                        ? AppColors.primaryGradient 
                        : null,
                      color: (_pin.length == 4 && !_isLoading) 
                        ? null 
                        : AppColors.border,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: (_pin.length == 4 && !_isLoading) 
                        ? [
                            BoxShadow(
                              color: AppColors.primaryRose.withOpacity(0.4),
                              offset: const Offset(0, 6),
                              blurRadius: 18,
                            ),
                          ]
                        : null,
                    ),
                    child: ElevatedButton(
                      onPressed: (_pin.length == 4 && !_isLoading && !securityState.isLocked)
                          ? () => _verifyPin()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Unlock Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (isAuthenticated)
                  TextButton(
                    onPressed: _handleForgotPin,
                    child: const Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        color: AppColors.primaryRose,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      const Text(
                        "Can't remember your PIN?",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Please contact support if you're using anonymous mode.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
              const SizedBox(height: 24),
              if (widget.allowCancel)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textMid,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyPin() async {
    if (_pin.length != 4) return;
    
    setState(() => _isLoading = true);
    final security = ref.read(securityProvider.notifier);

    try {
      final verified = await security.verifyPinWithCloudFallback(_pin);

      if (verified) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ PIN verified successfully!'),
              backgroundColor: AppColors.sageGreen,
              duration: Duration(seconds: 1),
            ),
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              if (widget.onSuccess != null) {
                widget.onSuccess!();
              } else {
                context.go('/home');
              }
            }
          });
        }
      } else {
        setState(() => _pin = '');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPin() async {
    final auth = ref.read(firebaseAuthProvider);
    if (auth.currentUser == null || auth.currentUser!.isAnonymous) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN recovery is only available for premium/registered users'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Reset PIN', style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text(
            'We\'ll send a password reset link to your email. After resetting your password, you can set a new PIN for your device.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMid, fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await auth.sendPasswordResetEmail(email: auth.currentUser!.email!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Password reset email sent!'),
                        backgroundColor: AppColors.sageGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Send Email', style: TextStyle(color: AppColors.primaryRose, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );
    }
  }
}
