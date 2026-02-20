import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 100),
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
                  _buildArticleCard('🔬', 'Puberty', 'Your cycle — the 4 phases explained', '5 min · WHO Source', AppColors.sageGreen),
                  _buildArticleCard('🌿', 'Pain', 'Natural ways to ease period pain', '4 min · Evidence-based', AppColors.primaryRose),
                  _buildArticleCard('❌', 'Myths', '10 period myths — debunked!', '6 min · Global', Colors.orange),
                  _buildArticleCard('🩺', 'Doctor', 'When to see a doctor about your period', '3 min · Medical Guide', Colors.blue),
                  _buildArticleCard('💰', 'Hygiene', 'Affordable period products worldwide', '5 min · Global Resources', AppColors.lavender),
                  const SizedBox(height: 12),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '🌍 30+ languages supported',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomNav(context, 3)),
            Positioned(bottom: 44, left: MediaQuery.of(context).size.width / 2 - 26, child: _buildFAB(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search...',
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
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
    final categories = ['All', '🌸 Puberty', '🧼 Hygiene', '❌ Myths', '💊 Pain', '🏥 Doctor'];
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
              border: Border.all(color: isFirst ? AppColors.primaryRose : AppColors.border, width: 1.5),
            ),
            child: Text(
              cat,
              style: TextStyle(
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

  Widget _buildArticleCard(String icon, String tag, String title, String meta, Color tagColor) {
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
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    tag.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: tagColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int activeIndex) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(44)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, '🏠', 'Home', activeIndex == 0, '/home'),
          _buildNavItem(context, '🌸', 'Log', activeIndex == 1, '/log'),
          const SizedBox(width: 52),
          _buildNavItem(context, '✨', 'Insights', activeIndex == 2, '/insights'),
          _buildNavItem(context, '📖', 'Learn', activeIndex == 3, '/education'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String icon, String label, bool isActive, String route) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: TextStyle(fontSize: 20, transform: isActive ? (Matrix4.identity()..scale(1.15)) : null)),
          const SizedBox(height: 3),
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isActive ? AppColors.primaryRose : const Color(0xFFE0B0B0), letterSpacing: 0.4)),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/log'),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: AppColors.primaryRose.withOpacity(0.45), offset: const Offset(0, 6), blurRadius: 20)],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
