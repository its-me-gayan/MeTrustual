import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/period_journey_provider.dart';
import '../../../core/widgets/premium_gate.dart';
import '../widgets/cycle_circle.dart';
import '../widgets/mini_calendar.dart';
import '../providers/home_provider.dart';

class PeriodHomeContent extends ConsumerWidget {
  final int logsCount;

  const PeriodHomeContent({required this.logsCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(periodHomeDataProvider);
    final cycleDay = journey?.cycleDay ?? 0;
    final phaseLabel = journey?.phaseLabel ?? 'Loading… 🌸';
    final cycleLen = journey?.cycleLen ?? 28;
    final periodLen = journey?.periodLen ?? 5;

    return Column(
      children: [
        Center(child: CycleCircle(day: cycleDay, phase: phaseLabel)),
        const SizedBox(height: 16),
        _buildPillsRow(
          {
            'value': cycleLen.toString(),
            'label': 'Avg Cycle',
            'color': AppColors.primaryRose
          },
          {
            'value': periodLen.toString(),
            'label': 'Period Days',
            'color': const Color(0xFFC9A0D0)
          },
          third: {
            'value': logsCount.toString(),
            'label': 'Logged',
            'color': const Color(0xFF8AB88A)
          },
        ),
        const SizedBox(height: 16),
        _buildPredictionBanner(journey, cycleDay, cycleLen),
        const SizedBox(height: 16),
        const PremiumGate(
          message: 'Unlock Advanced Calendar',
          child: MiniCalendar(),
        ),
      ],
    );
  }

  Widget _buildPredictionBanner(
      PeriodHomeData? journey, int cycleDay, int cycleLen) {
    final fmt = DateFormat('MMM d');
    final fmtShort = DateFormat('d');

    final aiResult = journey?.aiResult;

    final smartCycleLen = journey?.cycleLen ?? cycleLen;
    final daysUntilPeriod = (smartCycleLen - cycleDay).clamp(0, smartCycleLen);
    final absoluteFallback =
        DateTime.now().add(Duration(days: daysUntilPeriod));

    final nextPeriod =
        aiResult?.nextPeriod ?? journey?.nextPeriod ?? absoluteFallback;

    final confidencePct = aiResult?.confidencePct ??
        ((journey?.learningProgress ?? 0.35) * 100).round();

    final isAi = aiResult != null;
    final aiLoading = journey?.aiLoading ?? false;
    final periodSub = aiLoading ? 'Calculating…' : '±2 days · $confidencePct%';

    final today = DateTime.now();
    DateTime ovulationDate = nextPeriod.subtract(const Duration(days: 14));
    DateTime fertileStart = ovulationDate.subtract(const Duration(days: 5));
    DateTime fertileEnd = ovulationDate.add(const Duration(days: 1));

    if (_isBeforeDay(fertileEnd, today)) {
      final nextCyclePeriod = nextPeriod.add(Duration(days: smartCycleLen));
      ovulationDate = nextCyclePeriod.subtract(const Duration(days: 14));
      fertileStart = ovulationDate.subtract(const Duration(days: 5));
      fertileEnd = ovulationDate.add(const Duration(days: 1));
    }

    final nextPeriodStr = fmt.format(nextPeriod);

    final fertileStr = fertileStart.month == fertileEnd.month
        ? '${fmt.format(fertileStart)}–${fmtShort.format(fertileEnd)}'
        : '${fmt.format(fertileStart)}–${fmt.format(fertileEnd)}';
    final ovulStr = fmt.format(ovulationDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF5F8), Color(0xFFFDE8F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0C0D0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                aiLoading
                    ? '✨ Calculating…'
                    : isAi
                        ? '🤖 AI Predictions'
                        : '🔮 Predictions',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFC080A0),
                    letterSpacing: 0.5),
              ),
              const Spacer(),
              if (isAi && !aiLoading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B7FC7).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('AI-powered',
                      style: GoogleFonts.nunito(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF9B7FC7))),
                ),
            ],
          ),
          const SizedBox(height: 8),
          aiLoading
              ? const SizedBox(
                  height: 40,
                  child: Center(
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFC080A0))),
                  ),
                )
              : IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildPredItem(
                              label: '🩸 Next period',
                              value: nextPeriodStr,
                              sub: periodSub)),
                      Container(
                          width: 1,
                          color: const Color(0xFFF0D8E0),
                          margin: const EdgeInsets.symmetric(horizontal: 10)),
                      Expanded(
                          child: _buildPredItem(
                              label: '🌿 Fertile window',
                              value: fertileStr,
                              sub: 'Ovulation ~$ovulStr')),
                    ],
                  ),
                ),
          if (isAi && aiResult!.insight.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF9B7FC7).withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(aiResult.insight,
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7B5FC7),
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isBeforeDay(DateTime date, DateTime reference) {
    final d = DateTime(date.year, date.month, date.day);
    final r = DateTime(reference.year, reference.month, reference.day);
    return d.isBefore(r);
  }

  Widget _buildPredItem(
      {required String label, required String value, required String sub}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFD0A0B8),
                letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark)),
        const SizedBox(height: 1),
        Text(sub,
            style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD0A0B8))),
      ],
    );
  }

  Widget _buildPillsRow(Map<String, dynamic> pill1, Map<String, dynamic> pill2,
      {Map<String, dynamic>? third}) {
    return Row(
      children: [
        _buildStatPill(pill1['value'], pill1['label'], color: pill1['color']),
        const SizedBox(width: 8),
        _buildStatPill(pill2['value'], pill2['label'], color: pill2['color']),
        if (third != null) ...[
          const SizedBox(width: 8),
          _buildStatPill(third['value'], third['label'], color: third['color']),
        ],
      ],
    );
  }

  Widget _buildStatPill(String value, String label, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color ?? AppColors.primaryRose)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}
