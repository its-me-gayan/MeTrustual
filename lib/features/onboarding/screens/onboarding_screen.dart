import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/notification_service.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';
import '../providers/onboarding_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String selectedLang = 'en';
  bool keepPrivate = true;
  bool backupData = false;
  final TextEditingController _nicknameController = TextEditingController();

  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'ms', 'name': 'Melayu', 'flag': '🇲🇾'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'more', 'name': 'More…', 'flag': '🌐'},
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.onboardingGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Header ──
                const SizedBox(height: 40),
                Text('☀️', style: GoogleFonts.nunito(fontSize: 52)),
                const SizedBox(height: 8),
                Text(
                  'onboarding_title'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'onboarding_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMid,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 30),

                // ── Language Grid ──
                _buildLangRow(languages[0], languages[1]),
                const SizedBox(height: 10),
                _buildLangRow(languages[2], languages[3]),
                const SizedBox(height: 10),
                _buildLangRow(languages[4], languages[5]),

                const SizedBox(height: 30),

                // ── Toggle Cards ──
                _buildToggleCard(
                  title: '🔒 Keep it private',
                  subtitle: 'No account, stays on your phone',
                  value: keepPrivate,
                  onChanged: (val) => setState(() => keepPrivate = val),
                ),
                const SizedBox(height: 10),
                _buildToggleCard(
                  title: '☁️ Backup my data',
                  subtitle: 'Encrypted, only you can see it',
                  value: backupData,
                  onChanged: (val) => setState(() => backupData = val),
                ),

                const SizedBox(height: 20),

                // ── Promise Card ──
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.sageGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.sageGreen.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🛡️ Our promise to you',
                        style: GoogleFonts.nunito(
                          color: AppColors.sageGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No ads. No selling your data. No judgement. Delete everything anytime.',
                        style: GoogleFonts.nunito(
                          color: AppColors.sageGreen.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Nickname Section ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('✨', style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          'What shall we call you?',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: TextField(
                        controller: _nicknameController,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Your name or nickname...',
                          hintStyle: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'This is just for you — shows on your home screen 💕',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ── CTA Buttons ──
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
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
                          onPressed: () async {
                            try {
                              final nickname = _nicknameController.text.trim();
                              if (nickname.isEmpty) {
                                NotificationService.showError(context, 'Please enter a nickname');
                                return;
                              }
                              await ref
                                  .read(onboardingProvider.notifier)
                                  .completeOnboarding(
                                    language: selectedLang,
                                    anonymousMode: keepPrivate,
                                    cloudSync: backupData,
                                    nickname: nickname,
                                  );

                              if (mounted) {
                                context.go('/mode-selection');
                              }
                            } catch (e) {
                              if (mounted) {
                                NotificationService.showError(context, 'Error: $e');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Begin your journey ✨',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMid),
                          children: [
                            const TextSpan(text: 'Already a premium user? '),
                            TextSpan(
                              text: 'Log In',
                              style: GoogleFonts.nunito(
                                  color: AppColors.primaryRose,
                                  fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangRow(Map<String, String> left, Map<String, String> right) {
    return Row(
      children: [
        Expanded(child: _buildLangTile(left)),
        const SizedBox(width: 10),
        Expanded(child: _buildLangTile(right)),
      ],
    );
  }

  Widget _buildLangTile(Map<String, String> lang) {
    final isSelected = selectedLang == lang['code'];
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLang = lang['code']!;
          if (lang['code'] != 'more') {
            context.setLocale(Locale(lang['code']!));
          }
        });
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.petalLight.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryRose : AppColors.border,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '${lang['flag']} ${lang['name']}',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: isSelected ? AppColors.primaryRose : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textDark),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryRose,
          ),
        ],
      ),
    );
  }
}
