import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import 'package:google_fonts/google_fonts.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String currentMode =
      'period'; // This should ideally come from user settings/onboarding

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppColors.textDark, size: 20),
                    onPressed: () => context.go('/home'),
                  ),
                  Text(
                    _getPageTitle(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _getPageSub(),
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              _buildModeSpecificInsightsContent(),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          AppBottomNav(activeIndex: _getNavIndex(_currentRoute)),
      floatingActionButton: const AppFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  String get _currentRoute {
    final String? location =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    return location ?? '/home';
  }

  int _getNavIndex(String route) {
    switch (route) {
      case '/home':
        return 0;
      case '/log':
        return 1;
      case '/insights':
        return 2;
      case '/education':
        return 3;
      default:
        return 0;
    }
  }

  String _getPageTitle() {
    switch (currentMode) {
      case 'period':
        return 'Your Story ✨';
      case 'preg':
        return 'Your Journey 💙';
      case 'ovul':
        return 'Your Fertility 🌿';
      default:
        return 'Insights';
    }
  }

  String _getPageSub() {
    switch (currentMode) {
      case 'period':
        return '6 months of data';
      case 'preg':
        return 'Week 24 of 40';
      case 'ovul':
        return '6 cycles tracked';
      default:
        return 'Overview';
    }
  }

  Widget _buildModeSpecificInsightsContent() {
    switch (currentMode) {
      case 'period':
        return Column(
          children: [
            _buildBigInsight(
              emoji: '🌿',
              title: 'You\'re beautifully regular!',
              subtitle:
                  'Your cycles have stayed between 27–29 days for 6 months. Your AI model is 92% accurate for your body 💕',
              accentColor: AppColors.primaryRose,
            ),
            const SizedBox(height: 20),
            PremiumGate(
              message: 'Unlock Cycle Analytics',
              child: _buildInsightCard(
                title: '📊 Cycle Length — Last 6 Months',
                content: _buildMiniChartPeriod(),
              ),
            ),
            const SizedBox(height: 20),
            _buildInsightCard(
              title: '🌸 Most common symptoms',
              content: Column(
                children: [
                  _buildBarRow('Cramps', 0.80, AppColors.primaryRose),
                  _buildBarRow('Fatigue', 0.58, const Color(0xFFA880C8)),
                  _buildBarRow('Headache', 0.38, const Color(0xFF6A9E7A)),
                  _buildBarRow('Bloating', 0.28, const Color(0xFF5A80C0)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInsightCard(
              title: '🔮 What\'s coming up',
              content: Column(
                children: [
                  _buildUpcomingRow(
                      '🩸 Next period', 'Mar 6 · 92%', AppColors.primaryRose),
                  _buildUpcomingRow('🌿 Fertile window', 'Feb 18–23',
                      const Color(0xFF6A9E7A)),
                  _buildUpcomingRow('◎ Ovulation', 'Feb 21 (today!)',
                      const Color(0xFF9870C0)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInsightCard(
              title: '💭 Mood by phase',
              content: Column(
                children: [
                  _buildBarRow('Menstrual', 0.30, AppColors.primaryRose,
                      emoji: '😔'),
                  _buildBarRow('Follicular', 0.90, const Color(0xFF6A9E7A),
                      emoji: '🥰'),
                  _buildBarRow('Ovulation', 0.85, const Color(0xFF6A9E7A),
                      emoji: '😊'),
                  _buildBarRow('Luteal', 0.50, const Color(0xFFA880C8),
                      emoji: '😐'),
                ],
              ),
            ),
          ],
        );
      case 'preg':
        return Column(
          children: [
            _buildBigInsight(
              emoji: '💙',
              title: 'You\'re doing amazing!',
              subtitle:
                  'Week 24 — you\'ve completed 60% of your pregnancy. Baby is developing beautifully and you\'ve been consistent with logging 💕',
              accentColor: const Color(0xFF4A70B0),
            ),
            const SizedBox(height: 20),
            PremiumGate(
              message: 'Unlock Kick Count Analytics',
              child: _buildInsightCard(
                title: '📊 Kick Count — Last 7 Days',
                content: _buildMiniChartPregnancy(),
              ),
            ),
            const SizedBox(height: 20),
            _buildInsightCard(
              title: '⚖️ Weight Gain Progress',
              content: Column(
                children: [
                  _buildBarRow('Current', 0.60, const Color(0xFF4A70B0),
                      value: '+7 kg'),
                  _buildBarRow('Recommended', 0.68, const Color(0xFF6A9E7A),
                      value: '+8 kg'),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '✅ You\'re within the healthy range for week 24',
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: const Color(0xFF7090B0),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInsightCard(
              title: '🗓️ Upcoming milestones',
              content: Column(
                children: [
                  _buildUpcomingRow(
                      '🩺 Glucose screening', 'Mar 3', const Color(0xFF4A70B0)),
                  _buildUpcomingRow('👶 3rd trimester begins', 'Week 28',
                      const Color(0xFF4A70B0)),
                  _buildUpcomingRow('🏥 Birth class starts', 'Mar 20',
                      const Color(0xFF4A70B0)),
                  _buildUpcomingRow(
                      '🎁 Due date', 'Jun 5', const Color(0xFF4A70B0)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInsightCard(
              title: '🌡️ Common symptoms this trimester',
              content: Column(
                children: [
                  _buildBarRow('Fatigue', 0.72, const Color(0xFF4A70B0),
                      value: '9d'),
                  _buildBarRow('Back pain', 0.55, const Color(0xFF4A70B0),
                      value: '7d'),
                  _buildBarRow('Heartburn', 0.38, const Color(0xFF4A70B0),
                      value: '5d'),
                ],
              ),
            ),
          ],
        );
      case 'ovul':
        return Column(
          children: [
            _buildBigInsight(
              emoji: '🎯',
              title: 'Ovulation confirmed today!',
              subtitle:
                  'Your BBT rise + egg-white mucus + high OPK confirms ovulation on Day 14. Your pattern is very consistent — 89% prediction accuracy 🌿',
              accentColor: const Color(0xFF5A8E6A),
            ),
            const SizedBox(height: 20),
            PremiumGate(
              message: 'Unlock BBT Charting',
              child: _buildInsightCard(
                title: '🌡️ BBT Chart — Last 14 Days',
                content: _buildBBTChart(),
              ),
            ),
            const SizedBox(height: 20),
            _buildInsightCard(
              title: '📊 Fertile Window — Last 6 Cycles',
              content: Column(
                children: [
                  _buildBarRow('Oct', 0.60, const Color(0xFF5A8E6A),
                      value: 'Day 13'),
                  _buildBarRow('Nov', 0.65, const Color(0xFF5A8E6A),
                      value: 'Day 14'),
                  _buildBarRow('Dec', 0.60, const Color(0xFF5A8E6A),
                      value: 'Day 13'),
                  _buildBarRow('Jan', 0.65, const Color(0xFF5A8E6A),
                      value: 'Day 14'),
                  _buildBarRow('Feb', 0.65, const Color(0xFF5A8E6A),
                      value: 'Day 14'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInsightCard(
              title: '🔮 Upcoming predictions',
              content: Column(
                children: [
                  _buildUpcomingRow('🟢 Fertile window closes', 'Feb 23',
                      const Color(0xFF5A8E6A)),
                  _buildUpcomingRow(
                      '🩸 Next period due', 'Mar 6', AppColors.primaryRose),
                  _buildUpcomingRow('🌿 Next fertile window', 'Mar 18–24',
                      const Color(0xFF5A8E6A)),
                  _buildUpcomingRow(
                      '◎ Next ovulation', 'Mar 21', const Color(0xFF9870C0)),
                ],
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildBigInsight({
    required String emoji,
    required String title,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: GoogleFonts.nunito(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required Widget content,
    Color? accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (accentColor ?? Colors.black).withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildMiniChartPeriod() {
    final List<double> heights = [0.70, 0.80, 0.73, 0.85, 0.76, 0.78];
    final List<String> labels = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(heights.length, (index) {
            return Container(
              width: 16,
              height: 80 * heights[index],
              decoration: BoxDecoration(
                color: index == 3
                    ? AppColors.primaryRose
                    : AppColors.primaryRose.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: labels
              .map((label) => Text(
                    label,
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMiniChartPregnancy() {
    final List<double> heights = [0.60, 0.75, 0.65, 0.90, 0.80, 0.70, 0.85];
    final List<String> labels = [
      'Sat',
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri'
    ];
    final Color accentColor = const Color(0xFF4A70B0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(heights.length, (index) {
            return Container(
              width: 16,
              height: 80 * heights[index],
              decoration: BoxDecoration(
                color: index == 3 || index == 6
                    ? accentColor
                    : accentColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: labels
              .map((label) => Text(
                    label,
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBBTChart() {
    final List<double> bbtValues = [
      30, 35, 32, 28, 33, // Pre-ovulation
      38, 42, 40, 45, 48, 46, 52, 55, // Post-ovulation
      80 // Peak
    ];
    final Color accentColor = const Color(0xFF5A8E6A);

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(bbtValues.length, (index) {
                return Container(
                  width: 12,
                  height: bbtValues[index],
                  decoration: BoxDecoration(
                    color: index < 5
                        ? accentColor.withOpacity(0.5)
                        : (index == bbtValues.length - 1
                            ? accentColor
                            : accentColor.withOpacity(0.7)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            Positioned(
              right: MediaQuery.of(context).size.width *
                  0.08, // Approximate position
              bottom: 0,
              top: 0,
              child: Container(
                width: 2,
                color: accentColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Day 1',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
            Text('Ovulation ↑',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
            Text('Today',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildBarRow(String name, double fillFactor, Color color,
      {String? emoji, String? value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              name,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
          ),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fillFactor,
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        LinearGradient(colors: [color.withOpacity(0.5), color]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                emoji ?? value ?? '${(fillFactor * 10).round()}×',
                style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
                fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
