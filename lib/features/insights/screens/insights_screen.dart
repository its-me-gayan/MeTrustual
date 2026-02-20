import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/providers/home_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeDataProvider);

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'insights_title'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildBigInsight(homeData),
              const SizedBox(height: 16),
              _buildChartCard(homeData),
              const SizedBox(height: 10),
              _buildSymptomCard(),
              const SizedBox(height: 10),
              _buildUpcomingCard(homeData),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeIndex: 2),
      floatingActionButton: const AppFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBigInsight(Map<String, dynamic>? homeData) {
    final avgCycle = homeData?['prediction']?.averageLength ?? 28;
    String message = 'Start logging your cycle to see personalized insights! 💕';
    if (homeData != null) {
      message = 'Your average cycle is $avgCycle days. Your body knows what it\'s doing 💕';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFCE8E8), Color(0xFFFCE8F8)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFCD0D8), width: 1.5),
      ),
      child: Column(
        children: [
          const Text('🌿', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 6),
          const Text(
            'Cycle Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMid, fontWeight: FontWeight.w600, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(Map<String, dynamic>? homeData) {
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

  Widget _buildUpcomingCard(Map<String, dynamic>? homeData) {
    final prediction = homeData?['prediction'];
    final nextPeriod = prediction != null 
        ? DateFormat('MMM dd').format(prediction.nextPeriodDate)
        : '---';
    final fertileStart = prediction != null 
        ? DateFormat('MMM dd').format(prediction.fertileWindowStart)
        : '---';
    final fertileEnd = prediction != null 
        ? DateFormat('MMM dd').format(prediction.fertileWindowEnd)
        : '---';

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
          _buildUpcomingRow('🩸 Next period', '$nextPeriod · 85%', AppColors.primaryRose),
          _buildUpcomingRow('🌿 Fertile window', '$fertileStart–$fertileEnd', AppColors.sageGreen),
          _buildUpcomingRow('◎ Ovulation', prediction != null ? 'Predicted' : '---', AppColors.lavender),
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
}

class _BarLabel extends StatelessWidget {
  final String label;
  const _BarLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 28, child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted)));
  }
}
