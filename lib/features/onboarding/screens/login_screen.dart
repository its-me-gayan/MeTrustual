import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/uuid_persistence_service.dart';
import '../../../core/services/anonymous_migration_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/notification_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// Set to true when this login is triggered from the anonymous → premium
  /// upgrade flow so the UI subtitle changes accordingly.
  final bool isPremiumFlow;

  const LoginScreen({super.key, this.isPremiumFlow = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please enter both email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(firebaseAuthProvider);
      final firestore = ref.read(firestoreProvider);

      // ── A: Snapshot anonymous data BEFORE auth state changes ──────────
      // We must capture this now — once we call signIn the anonymous user
      // reference is gone from auth.currentUser.
      final currentUser = auth.currentUser;
      final isCurrentlyAnonymous =
          currentUser != null && currentUser.isAnonymous;
      AnonymousSnapshot? anonSnapshot;
      User? anonymousAuthUser; // keep a reference for later cleanup

      if (isCurrentlyAnonymous) {
        anonymousAuthUser = currentUser;
        anonSnapshot = await AnonymousMigrationService.captureAnonymousData(
          auth: auth,
          firestore: firestore,
        );
      }

      // ── B: Sign in to the permanent account ───────────────────────────
      final userCredential = await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;
      if (user == null) {
        _showError('Login failed. Please try again.');
        return;
      }

      // ── C: Migrate anonymous data (when applicable) ───────────────────
      if (anonSnapshot != null && anonSnapshot.hasAnyData) {
        // SECURITY CHECK: does the account they just signed in to already
        // have its own real data?  If yes we ask for explicit confirmation.
        final targetHasData =
            await AnonymousMigrationService.targetAccountHasData(
          targetUid: user.uid,
          firestore: firestore,
        );

        bool proceedWithMigration = true;

        if (targetHasData) {
          // Show dialog — user must actively confirm before we touch anything.
          // This also prevents an adversary who stole credentials from silently
          // corrupting the victim's account (they'd have to tap "Merge" and
          // even then the merge is non-destructive).
          proceedWithMigration = await _showMergeConfirmationDialog();
        }

        if (proceedWithMigration) {
          final result = await AnonymousMigrationService.mergeIntoTarget(
            snapshot: anonSnapshot,
            targetUid: user.uid,
            firestore: firestore,
          );

          if (result.success) {
            // Queue the anonymous account for deletion via Cloud Function.
            // Writes to pending_deletions/{uid} which the server watches.
            await AnonymousMigrationService.queueAnonymousAccountDeletion(
              anonymousUid: anonSnapshot.anonymousUid,
              firestore: firestore,
            );

            if (mounted && result.journeyMigrated ||
                result.settingsMigrated ||
                result.logsMigrated > 0) {
              final msg = _buildSuccessMessage(result);
              NotificationService.showSuccess(context, msg);
            }
          }
        }
      }

      // ── D: Persist UID locally and navigate ───────────────────────────
      await UUIDPersistenceService.saveUUID(user.uid);

      final isPinSet = await BiometricService.isBiometricSetUp();
      if (mounted) {
        if (isPinSet) {
          context.go('/home');
        } else {
          context.go('/biometric-setup/${user.uid}');
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyAuthError(e.code));
    } catch (e) {
      _showError('Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showMergeConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              '⚠️ This account already has data',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            content: Text(
              'This account has its own history.\n\n'
              'Your current session data can be merged in — but '
              'nothing in the existing account will be overwritten.\n\n'
              'Only tap "Merge" if this is your own account.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textMid,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Skip merge',
                  style: GoogleFonts.nunito(
                      color: AppColors.textMid, fontWeight: FontWeight.w700),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRose,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Merge my data',
                  style: GoogleFonts.nunito(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _buildSuccessMessage(MigrationResult result) {
    final parts = <String>[];
    if (result.journeyMigrated) parts.add('cycle history');
    if (result.settingsMigrated) parts.add('settings');
    if (result.logsMigrated > 0)
      parts.add('${result.logsMigrated} log entries');
    if (parts.isEmpty) return 'Welcome back!';
    return 'Transferred: ${parts.join(', ')} ✨';
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      default:
        return 'Login failed. Please check your details.';
    }
  }

  void _showError(String message) {
    NotificationService.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('🌸', style: GoogleFonts.nunito(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isPremiumFlow
                    ? 'Log in to activate premium on this account'
                    : 'Log in to sync your data across devices',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.textMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'your@email.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hint: '••••••••',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textMid,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    if (_emailController.text.isNotEmpty) {
                      ref.read(firebaseAuthProvider).sendPasswordResetEmail(
                            email: _emailController.text.trim(),
                          );
                      NotificationService.showSuccess(
                          context, 'Password reset email sent!');
                    } else {
                      _showError('Please enter your email first');
                    }
                  },
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.nunito(
                      color: AppColors.primaryRose,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
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
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Log In',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: GoogleFonts.nunito(
                          color: AppColors.textMid,
                          fontWeight: FontWeight.w600),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.nunito(
                          color: AppColors.primaryRose,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.nunito(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
