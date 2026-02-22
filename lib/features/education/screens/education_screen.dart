import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../core/providers/dynamic_content_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import 'package:google_fonts/google_fonts.dart';

class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final educationAsync = ref.watch(educationContentProvider);

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'learn_title'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildSearchBox(),
              const SizedBox(height: 16),
              _buildCategoryScroll(),
              const SizedBox(height: 20),
              educationAsync.when(
                data: (articles) {
                  if (articles.isEmpty) {
                    return const Center(
                      child: Text(
                          'No articles found. Admin panel coming soon! 🌸'),
                    );
                  }
                  return Column(
                    children: articles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final article = entry.value;
                      final card = _buildArticleCard(
                        article['icon'] ?? '📖',
                        article['tag'] ?? 'Info',
                        article['title'] ?? 'Untitled',
                        article['meta'] ?? '',
                        _getColorFromHex(article['tagColor'] ?? '#F7A8B8'),
                      );

                      // Lock articles after the first two
                      if (index >= 2) {
                        return PremiumGate(
                          isOverlay: true,
                          message: 'Premium Article',
                          child: card,
                        );
                      }
                      return card;
                    }).toList(),
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading education: $err'),
              ),
              const SizedBox(height: 12),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '🌍 30+ languages supported',
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeIndex: 3),
      floatingActionButton: const AppFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Widget _buildSearchBox() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search...',
        prefixIcon:
            const Icon(Icons.search, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategoryScroll() {
    final categories = [
      'All',
      '🌸 Puberty',
      '🧼 Hygiene',
      '❌ Myths',
      '💊 Pain',
      '🏥 Doctor'
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isFirst = cat == 'All';
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isFirst ? AppColors.primaryRose : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isFirst ? AppColors.primaryRose : AppColors.border,
                  width: 1.5),
            ),
            child: Text(
              cat,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isFirst ? Colors.white : AppColors.textDark,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildArticleCard(
      String icon, String tag, String title, String meta, Color tagColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(icon, style: GoogleFonts.nunito(fontSize: 24)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: tagColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    tag.toUpperCase(),
                    style: GoogleFonts.nunito(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: tagColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
