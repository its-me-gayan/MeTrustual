import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../core/providers/dynamic_content_provider.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import 'package:google_fonts/google_fonts.dart';
import 'article_detail_screen.dart';

// Category model — maps display label → keyword used to match article tags
class _Category {
  final String label;
  final String filter;
  const _Category(this.label, this.filter);
}

// ── Mode → theme color ─────────────────────────────────────────
Color _colorForMode(String mode) {
  switch (mode) {
    case 'preg':
      return const Color(0xFF4A70B0); // blue
    case 'ovul':
      return const Color(0xFF5A8E6A); // green
    default:
      return AppColors.primaryRose; // period — rose
  }
}

class EducationScreen extends ConsumerStatefulWidget {
  const EducationScreen({super.key});

  @override
  ConsumerState<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<EducationScreen> {
  final List<_Category> _categories = const [
    _Category('All', ''),
    _Category('🌸 Puberty', 'puberty'),
    _Category('🧼 Hygiene', 'hygiene'),
    _Category('❌ Myths', 'myths'),
    _Category('💊 Period Pain', 'period_pain'),
    _Category('🏥 Sexual Health', 'sexual_health'),
  ];

  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(Map<String, dynamic> article) {
    final category = _categories[_selectedIndex];
    final tag = (article['tag'] ?? '').toString().toLowerCase();
    final tagLabel = (article['tag_label'] ?? '').toString().toLowerCase();
    final title = (article['title'] ?? '').toString().toLowerCase();
    final query = _searchQuery.toLowerCase();

    if (category.filter.isNotEmpty && !tag.contains(category.filter))
      return false;
    if (query.isNotEmpty &&
        !title.contains(query) &&
        !tag.contains(query) &&
        !tagLabel.contains(query)) return false;
    return true;
  }

  void _openArticle(
      BuildContext context, Map<String, dynamic> article, Color modeColor) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            ArticleDetailScreen(article: article, modeColor: modeColor),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final educationAsync = ref.watch(educationContentProvider);
    final mode = ref.watch(modeProvider);
    final modeColor = _colorForMode(mode);

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('learn_title'.tr(),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildSearchBox(modeColor),
              const SizedBox(height: 16),
              _buildCategoryScroll(modeColor),
              const SizedBox(height: 20),
              educationAsync.when(
                data: (articles) {
                  if (articles.isEmpty) {
                    return const Center(
                      child: Text(
                          'No articles found. Admin panel coming soon! 🌸'),
                    );
                  }
                  final filtered = articles.where(_matchesFilter).toList();
                  if (filtered.isEmpty) return _buildEmptyState(modeColor);

                  return Column(
                    children: filtered.asMap().entries.map((entry) {
                      final index = entry.key;
                      final article = entry.value;
                      final card = _buildArticleCard(
                        context,
                        article,
                        modeColor,
                        article['icon'] ?? '📖',
                        article['tag_label'] ?? 'Info',
                        article['title'] ?? 'Untitled',
                        article['duration'] ?? '',
                        _getColorFromHex(article['tag_color'] ?? '#F7A8B8'),
                      );

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
                loading: () =>
                    Center(child: CircularProgressIndicator(color: modeColor)),
                error: (err, _) => Text('Error loading education: $err'),
              ),
              const SizedBox(height: 12),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
      bottomNavigationBar: const AppBottomNav(activeIndex: 2),
      floatingActionButton: const AppFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ─────────────────────────────────────────────────────────────

  Widget _buildSearchBox(Color modeColor) {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: 'Search articles...',
        prefixIcon:
            Icon(Icons.search, color: modeColor.withOpacity(0.6), size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Icon(Icons.close,
                    color: AppColors.textMuted, size: 18),
              )
            : null,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: modeColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategoryScroll(Color modeColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          final isSelected = index == _selectedIndex;

          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? modeColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? modeColor : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: modeColor.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : null,
              ),
              child: Text(
                cat.label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(Color modeColor) {
    final cat = _categories[_selectedIndex];
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _searchQuery.isNotEmpty ? '🔍' : cat.label.split(' ').first,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'No articles in ${cat.label} yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Text(
              'Check back soon 🌸',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: modeColor.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse(hexColor, radix: 16));
  }

  Widget _buildArticleCard(
    BuildContext context,
    Map<String, dynamic> article,
    Color modeColor,
    String icon,
    String tag,
    String title,
    String meta,
    Color tagColor,
  ) {
    return GestureDetector(
      onTap: () => _openArticle(context, article, modeColor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            // Icon tinted with mode background
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: modeColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
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
                  Text(title,
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(meta,
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: modeColor.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
