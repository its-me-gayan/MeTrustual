import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLoading = false;
  String _selectedPlan = 'annual';

  void _showError(String message) {
    NotificationService.showError(context, message);
  }

  Future<void> _handleSubscribe() async {
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;

    if (user == null || user.isAnonymous) {
      await _showSignUpSheet();
    } else {
      await _processMockPayment(user.uid);
    }
  }

  Future<void> _showSignUpSheet() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSheetLoading = false;
    final currentMode = ref.read(modeProvider);
    final themeColor = AppColors.getModeColor(currentMode);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(color: Color(0xFFFFF8F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            left: 24,
            right: 24,
            top: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text:  TextSpan(
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    // fontFamily: 'Nunito',
                  ),
                  children: [
                    TextSpan(text: 'Create your '),
                    TextSpan(
                      text: 'account',
                      style: GoogleFonts.nunito(
                          color: themeColor,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Secure your data and unlock all features.',
                style: GoogleFonts.nunito(
                    color: AppColors.textMid,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                  emailController, 'Email Address', Icons.email_outlined),
              const SizedBox(height: 16),
              _buildTextField(
                  passwordController, 'Password', Icons.lock_outline,
                  isObscure: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSheetLoading
                      ? null
                      : () async {
                          if (emailController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            _showError('Please fill in all fields');
                            return;
                          }
                          setSheetState(() => isSheetLoading = true);
                          try {
                            final auth = ref.read(firebaseAuthProvider);
                            final currentUser = auth.currentUser;

                            if (currentUser != null &&
                                currentUser.isAnonymous) {
                              final credential = EmailAuthProvider.credential(
                                  email: emailController.text,
                                  password: passwordController.text);
                              await currentUser.linkWithCredential(credential);
                            } else {
                              await auth.createUserWithEmailAndPassword(
                                  email: emailController.text,
                                  password: passwordController.text);
                            }

                            if (context.mounted) Navigator.pop(context);
                            final newUser = auth.currentUser;
                            if (newUser != null) {
                              await _processMockPayment(newUser.uid);
                            }
                          } catch (e) {
                            _showError(e.toString());
                          } finally {
                            setSheetState(() => isSheetLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: isSheetLoading
                      ? SizedBox(width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Create Account & Continue',
                          style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {bool isObscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(
              color: AppColors.textMuted, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Future<void> _processMockPayment(String uid) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('users').doc(uid).set({
        'isPremium': true,
        'subscriptionPlan': _selectedPlan,
        'subscriptionDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    final currentMode = ref.read(modeProvider);
    final themeColor = AppColors.getModeColor(currentMode);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Color(0xFFFFF8F5),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child:
                    const Icon(Icons.star, color: Color(0xFF4CAF50), size: 40),
              ),
              const SizedBox(height: 24),
              Text('You\'re Premium!',
                  style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text('Welcome to the family. Your journey just got even better.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600, color: AppColors.textMid),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text('Start Exploring',
                      style: GoogleFonts.nunito(
                          color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(modeProvider);
    final themeColor = AppColors.getModeColor(currentMode);

    return Scaffold(
      backgroundColor: Color(0xFFFFF8F5),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(themeColor),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFeatureItem('📊', 'Advanced Insights',
                          'Deep dive into your cycle and health patterns.'),
                      _buildFeatureItem('☁️', 'Secure Cloud Sync',
                          'Sync your data safely across all your devices.'),
                      _buildFeatureItem('📖', 'Expert Library',
                          'Unlimited access to expert-reviewed health guides.'),
                      _buildFeatureItem('🔔', 'Smart Reminders',
                          'Personalized alerts tailored to your unique cycle.'),
                      const SizedBox(height: 40),
                      Text('Select a plan',
                          style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark)),
                      const SizedBox(height: 16),
                      _buildPlanCard('annual', 'Annual', '\$49.99',
                          'Best Value • \$4.16/mo', themeColor),
                      const SizedBox(height: 12),
                      _buildPlanCard(
                          'monthly', 'Monthly', '\$9.99', 'Cancel anytime', themeColor),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 32,
            left: 22,
            right: 22,
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                  elevation: 8,
                  shadowColor: themeColor.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Unlock Premium Now',
                        style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textDark, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color themeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 80, 22, 40),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
              color: Color(0xFFFCE8E4), blurRadius: 20, offset: Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Text('✨', style: GoogleFonts.nunito(fontSize: 32)),
          ),
          const SizedBox(height: 20),
          RichText(
            textAlign: TextAlign.center,
            text:  TextSpan(
              style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  // fontFamily: 'Nunito'
                  ),
              children: [
                TextSpan(text: 'MeTrustual '),
                TextSpan(
                    text: 'Premium',
                    style: GoogleFonts.nunito(
                        color: themeColor,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Experience the full power of personalized health.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMid),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5)),
            alignment: Alignment.center,
            child: Text(emoji, style: GoogleFonts.nunito(fontSize: 24)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark)),
                Text(desc,
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMid)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String id, String title, String price, String sub, Color themeColor) {
    final isSelected = _selectedPlan == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: isSelected ? themeColor : AppColors.border,
              width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: themeColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected
                        ? themeColor
                        : AppColors.textMuted,
                    width: 2),
                color: isSelected ? themeColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark)),
                  Text(sub,
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted)),
                ],
              ),
            ),
            Text(price,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }
}
