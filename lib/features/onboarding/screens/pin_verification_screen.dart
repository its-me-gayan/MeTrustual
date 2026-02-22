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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryRose.withOpacity(0.1),
                ),
                child: const Center(
                  child: Text('🔐', style: TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Unlock Your Account',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your PIN to continue',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              if (securityState.isLocked)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    '⏱️ ${securityState.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                )
              else ...[
                CustomPinInput(
                  label: 'Enter PIN',
                  hintText: '• • • •',
                  onChanged: (val) => setState(() => _pin = val),
                ),
                const SizedBox(height: 16),
                if (securityState.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      securityState.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_pin.length == 4 && !_isLoading && !securityState.isLocked)
                        ? () => _verifyPin()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRose,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 8,
                      shadowColor: AppColors.primaryRose.withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Unlock',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                if (isAuthenticated && _showForgotOption)
                  TextButton(
                    onPressed: _handleForgotPin,
                    child: const Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        color: AppColors.primaryRose,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else if (isAuthenticated)
                  TextButton(
                    onPressed: () => setState(() => _showForgotOption = true),
                    child: const Text(
                      'Can\'t remember your PIN?',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              if (widget.allowCancel)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textMuted,
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
            content: Text('Please log in to reset your PIN'),
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
          title: const Text('Reset PIN'),
          content: const Text(
            'We\'ll send a password reset link to your email. After resetting your password, you can set a new PIN.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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
              child: const Text('Send Reset Email'),
            ),
          ],
        ),
      );
    }
  }
}
