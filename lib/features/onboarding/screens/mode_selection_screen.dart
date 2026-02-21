import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8F5), Color(0xFFFEF0F5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      fontFamily: 'Nunito',
                      height: 1.25,
                    ),
                    children: [
                      TextSpan(text: 'How should we\n'),
                      TextSpan(
                        text: 'help you',
                        style: TextStyle(
                          color: AppColors.primaryRose,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(text: ' today?'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select a mode to personalise your experience.\nYou can switch anytime from your home screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFB09090),
                    fontWeight: FontWeight.w600,
                    lineHeight: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                
                Expanded(
                  child: Column(
                    children: [
                      _buildModeCard(
                        context,
                        emoji: '🩸',
                        title: 'Track my period',
                        desc: 'Predict your next period, fertile window, and manage symptoms.',
                        color: AppColors.primaryRose,
                        mode: 'period',
                      ),
                      const SizedBox(height: 12),
                      _buildModeCard(
                        context,
                        emoji: '🤰',
                        title: 'I\'m pregnant',
                        desc: 'Week-by-week baby updates, kick counter, and wellness tracking.',
                        color: const Color(0xFF4A70B0),
                        mode: 'preg',
                      ),
                      const SizedBox(height: 12),
                      _buildModeCard(
                        context,
                        emoji: '🌿',
                        title: 'Track ovulation',
                        desc: 'Advanced tracking for conception or natural family planning.',
                        color: const Color(0xFF5A8E6A),
                        mode: 'ovul',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String desc,
    required Color color,
    required String mode,
  }) {
    return GestureDetector(
      onTap: () => context.go('/journey/$mode'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFCE8E4), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 38)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB09090),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.4), size: 22),
          ],
        ),
      ),
    );
  }
}
