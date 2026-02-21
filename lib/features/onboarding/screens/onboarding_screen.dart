import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String selectedLang = 'en';
  bool keepPrivate = true;
  bool backupData = false;

  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'ms', 'name': 'Melayu', 'flag': '🇲🇾'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'more', 'name': 'More…', 'flag': '🌐'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.onboardingGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Header ──
                const Spacer(flex: 2),
                const Text('🌸', style: TextStyle(fontSize: 52)),
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
                const Spacer(flex: 2),

                // ── Language Grid (3 rows x 2 cols using Row/Column) ──
                _buildLangRow(languages[0], languages[1]),
                const SizedBox(height: 10),
                _buildLangRow(languages[2], languages[3]),
                const SizedBox(height: 10),
                _buildLangRow(languages[4], languages[5]),

                const Spacer(flex: 2),

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

                const Spacer(flex: 2),

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
                      const Text(
                        '🛡️ Our promise to you',
                        style: TextStyle(
                          color: AppColors.sageGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No ads. No selling your data. No judgement. Delete everything anytime.',
                        style: TextStyle(
                          color: AppColors.sageGreen.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── CTA Button ──
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
                        await ref
                            .read(onboardingProvider.notifier)
                            .completeOnboarding(
                              language: selectedLang,
                              anonymousMode: keepPrivate,
                              cloudSync: backupData,
                            );
                        if (mounted) context.go('/mode-selection');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('onboarding_cta'.tr()),
                    ),
                  ),
                ),

                const Spacer(flex: 3),
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
          style: TextStyle(
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
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textDark),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
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
