import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../models/insights_mode_config.dart';
import '../providers/insights_provider.dart';
import '../widgets/period_insights_content.dart';
import '../widgets/pregnancy_insights_content.dart';
import '../widgets/ovulation_insights_content.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    final insightsAsync = ref.watch(insightsDataProvider);
    final config = InsightsModeConfig.fromMode(mode);
    final accentColor = _modeColor(mode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: insightsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRose)),
          error: (err, _) => Center(child: Text('Error loading insights: $err')),
          data: (data) => CustomScrollView(
            slivers: [
              _buildAppBar(context, config, data, accentColor),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildModeContent(mode, data, accentColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(activeIndex: _getNavIndex(context)),
      floatingActionButton: const AppFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  int _getNavIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/insights')) return 1;
    if (location.startsWith('/education')) return 2;
    if (location.startsWith('/care')) return 3;
    return 1;
  }

  Widget _buildAppBar(BuildContext context, InsightsModeConfig config,
      InsightsData data, Color accentColor) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark, size: 20),
        onPressed: () => context.go('/home'),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, right: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(config.title,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
            Text(config.subtitle(data),
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildModeContent(
      String mode, InsightsData data, Color accentColor) {
    switch (mode) {
      case 'preg':
        return PregnancyInsightsContent(data: data, accentColor: accentColor)
            .build(null);
      case 'ovul':
        return OvulationInsightsContent(data: data, accentColor: accentColor)
            .build(null);
      default:
        return PeriodInsightsContent(data: data, accentColor: accentColor)
            .build(null);
    }
  }

  Color _modeColor(String mode) {
    switch (mode) {
      case 'preg':
        return const Color(0xFF4A70B0);
      case 'ovul':
        return const Color(0xFF5A8E6A);
      default:
        return AppColors.primaryRose;
    }
  }
}
