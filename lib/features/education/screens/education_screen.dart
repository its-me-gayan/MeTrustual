import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../core/providers/dynamic_content_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import 'package:google_fonts/google_fonts.dart';

// Category model — maps display label → keyword used to match article tags
class _Category {
  final String label;
  final String filter; // matches against article['tag']

  const _Category(this.label, this.filter);
}

class EducationScreen extends ConsumerStatefulWidget {
  const EducationScreen({super.key});

  @override
  ConsumerState<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<EducationScreen> {
  // ── Category state ──
  final List<_Category> _categories = const [
    _Category('All', ''), // empty string = show all
    _Category('🌸 Puberty', 'puberty'),
    _Category('🧼 Hygiene', 'hygiene'),
    _Category('❌ Myths', 'myths'),
    _Category('💊 Period Pain', 'period_pain'),
    _Category('🏥 Sexual Health', 'sexual_health'),
  ];

  int _selectedIndex = 0; // 0 = All

  // ── Search state ──
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Returns true if an article matches the current category + search query
  bool _matchesFilter(Map<String, dynamic> article) {
    final category = _categories[_selectedIndex];
    final tag = (article['tag'] ?? '').toString().toLowerCase();
    final tagLabel = (article['tag_label'] ?? '').toString().toLowerCase();
    final title = (article['title'] ?? '').toString().toLowerCase();
    final query = _searchQuery.toLowerCase();

    // Category filter — skip when "All"
    if (category.filter.isNotEmpty && !tag.contains(category.filter)) {
      return false;
    }

    // Search filter
    if (query.isNotEmpty && 
        !title.contains(query) && 
        !tag.contains(query) && 
        !tagLabel.contains(query)) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
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

                  // Apply category + search filter
                  final filtered =
                      articles.where((a) => _matchesFilter(a)).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return Column(
                    children: filtered.asMap().entries.map((entry) {
                      final index = entry.key;
                      final article = entry.value;
                      final card = _buildArticleCard(
                        article['icon'] ?? '📖',
                        article['tag_label'] ?? 'Info',
                        article['title'] ?? 'Untitled',
                        article['duration'] ?? '',
                        _getColorFromHex(article['tag_color'] ?? '#F7A8B8'),
                      );

                      // Lock articles after the first two — same rule as original
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading education: $err'),
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
  //  WIDGETS
  // ─────────────────────────────────────────────────────────────

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: 'Search articles...',
        prefixIcon:
            const Icon(Icons.search, color: AppColors.textMuted, size: 20),
        // Clear button when there's a query
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
          borderSide:
              const BorderSide(color: AppColors.primaryRose, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategoryScroll() {
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
                color: isSelected ? AppColors.primaryRose : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primaryRose : AppColors.border,
                  width: 1.5,
                ),
                // Subtle shadow on active tab
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryRose.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
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

  // Shown when the active filter returns no results
  Widget _buildEmptyState() {
    final cat = _categories[_selectedIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
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
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back soon 🌸',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Unchanged from original ──
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse(hexColor, radix: 16));
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
