import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

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
                    'insights_title'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildBigInsight(),
                  const SizedBox(height: 16),
                  _buildChartCard(),
                  const SizedBox(height: 10),
                  _buildSymptomCard(),
                  const SizedBox(height: 10),
                  _buildUpcomingCard(),
                ],
              ),
            ),
            Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomNav(context, 2)),
            Positioned(bottom: 44, left: MediaQuery.of(context).size.width / 2 - 26, child: _buildFAB(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBigInsight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFCE8E8), Color(0xFFFCE8F8)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFCD0D8), width: 1.5),
      ),
      child: const Column(
        children: [
          Text('🌿', style: TextStyle(fontSize: 40)),
          SizedBox(height: 6),
          Text(
            'You\'re very regular!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          SizedBox(height: 4),
          Text(
            'Your cycles have been 27–30 days for 6 months. Your body knows what it\'s doing 💕',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMid, fontWeight: FontWeight.w600, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Cycle Length — Last 6 months',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(0.65),
                _buildBar(0.78),
                _buildBar(0.72),
                _buildBar(0.82, isHigh: true),
                _buildBar(0.74),
                _buildBar(0.76, opacity: 0.7),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BarLabel('Sep'), _BarLabel('Oct'), _BarLabel('Nov'),
              _BarLabel('Dec'), _BarLabel('Jan'), _BarLabel('Feb'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, {bool isHigh = false, double opacity = 1.0}) {
    return Container(
      width: 28,
      height: 100 * heightFactor,
      decoration: BoxDecoration(
        color: AppColors.primaryRose.withOpacity(isHigh ? 1.0 : 0.4 * opacity),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildSymptomCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌸 Most common symptoms',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          _buildSymptomRow('Cramps', 0.8, [const Color(0xFFFDD0D0), AppColors.primaryRose], 8),
          _buildSymptomRow('Fatigue', 0.58, [const Color(0xFFE0C8F0), AppColors.lavender], 6),
          _buildSymptomRow('Headache', 0.38, [const Color(0xFFC8E8D0), AppColors.sageGreen], 4),
        ],
      ),
    );
  }

  Widget _buildSymptomRow(String name, double factor, List<Color> colors, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMid),
            ),
          ),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: factor,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colors.last),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔮 What\'s coming up',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          _buildUpcomingRow('🩸 Next period', 'Mar 6 · 85%', AppColors.primaryRose),
          _buildUpcomingRow('🌿 Fertile window', 'Feb 18–23', AppColors.sageGreen),
          _buildUpcomingRow('◎ Ovulation', 'Today!', AppColors.lavender),
        ],
      ),
    );
  }

  Widget _buildUpcomingRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMid)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
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
          Text(icon, style: const TextStyle(fontSize: 20)),
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

class _BarLabel extends StatelessWidget {
  final String label;
  const _BarLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 28, child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted)));
  }
}
