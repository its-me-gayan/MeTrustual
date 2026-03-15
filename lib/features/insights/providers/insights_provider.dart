import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/prediction_engine.dart';
import '../../../features/home/providers/home_provider.dart';
import '../../../features/logging/providers/log_provider.dart';
import '../../../models/cycle_model.dart';
import '../../../models/daily_log_model.dart';

// ─── Data Models ────────────────────────────────────────────────────────────

class CycleChartPoint {
  final String label; // e.g. "Sep"
  final int length; // cycle length in days
  CycleChartPoint(this.label, this.length);
}

class SymptomStat {
  final String name;
  final int count;
  final double ratio; // 0-1 relative to max
  SymptomStat(this.name, this.count, this.ratio);
}

class MoodPhaseStat {
  final String phase;
  final double score; // 0-1
  final String emoji;
  MoodPhaseStat(this.phase, this.score, this.emoji);
}

class InsightsData {
  // Hero card
  final String heroTitle;
  final String heroSubtitle;
  final String heroEmoji;

  // Cycle regularity
  final int? minCycleLength;
  final int? maxCycleLength;
  final int cyclesTracked;
  final double predictionAccuracy; // 0-1
  final List<CycleChartPoint> cycleChart;

  // Symptoms
  final List<SymptomStat> topSymptoms;

  // Upcoming
  final DateTime? nextPeriodDate;
  final double nextPeriodConfidence;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final DateTime? ovulationDate;

  // Mood
  final List<MoodPhaseStat> moodByPhase;

  InsightsData({
    required this.heroTitle,
    required this.heroSubtitle,
    required this.heroEmoji,
    this.minCycleLength,
    this.maxCycleLength,
    required this.cyclesTracked,
    required this.predictionAccuracy,
    required this.cycleChart,
    required this.topSymptoms,
    this.nextPeriodDate,
    required this.nextPeriodConfidence,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    this.ovulationDate,
    required this.moodByPhase,
  });
}

// ─── Provider ───────────────────────────────────────────────────────────────

final insightsDataProvider =
    FutureProvider.autoDispose<InsightsData>((ref) async {
  final cyclesAsync = ref.watch(cycleListProvider);
  final logNotifier = ref.read(logProvider.notifier);

  final cycles = cyclesAsync.when(
    data: (c) => c,
    loading: () => <CycleModel>[],
    error: (_, __) => <CycleModel>[],
  );

  final logs = await logNotifier.getLogs();

  return _compute(cycles, logs);
});

// ─── Computation ─────────────────────────────────────────────────────────────

InsightsData _compute(List<CycleModel> cycles, List<DailyLog> logs) {
  // --- Cycle lengths -------------------------------------------------------
  final completedCycles = cycles
      .where((c) => c.length != null && c.length! > 15 && c.length! < 60)
      .toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));

  final cycleLengths = completedCycles.map((c) => c.length!).toList();

  final int? minLen = cycleLengths.isEmpty ? null : cycleLengths.reduce(min);
  final int? maxLen = cycleLengths.isEmpty ? null : cycleLengths.reduce(max);

  // Cycle chart — last 6 cycles with month label
  final chartCycles = completedCycles.length > 6
      ? completedCycles.sublist(completedCycles.length - 6)
      : completedCycles;

  final monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final cycleChart = chartCycles
      .map((c) => CycleChartPoint(
            monthNames[c.startDate.month - 1],
            c.length!,
          ))
      .toList();

  // --- Prediction ----------------------------------------------------------
  PredictionResult? prediction;
  if (cycles.isNotEmpty) {
    prediction = PredictionEngine.predictNextPeriod(
      lastPeriodStart: cycles.first.startDate,
      cycleLengths: cycleLengths,
    );
  }

  DateTime? nextPeriod = prediction?.date;
  double nextPeriodConf = prediction?.confidence ?? 0.0;

  DateTimeRange? fertileRange;
  DateTime? ovulation;
  if (prediction != null && nextPeriod != null) {
    fertileRange = PredictionEngine.predictFertileWindow(
      nextPeriodDate: nextPeriod,
      averageCycleLength: prediction.averageLength,
    );
    ovulation = nextPeriod.subtract(const Duration(days: 14));
  }

  // --- Symptoms from logs --------------------------------------------------
  final symptomCounts = <String, int>{};
  for (final log in logs) {
    for (final s in log.symptoms) {
      symptomCounts[s] = (symptomCounts[s] ?? 0) + 1;
    }
  }
  final sortedSymptoms = symptomCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final maxCount = sortedSymptoms.isEmpty ? 1 : sortedSymptoms.first.value;
  final topSymptoms = sortedSymptoms
      .take(4)
      .map((e) => SymptomStat(
            _formatSymptomName(e.key),
            e.value,
            e.value / maxCount,
          ))
      .toList();

  // --- Mood by phase -------------------------------------------------------
  // Map mood strings → score 0-1
  final moodScore = {
    'happy': 1.0,
    'great': 1.0,
    'energetic': 0.95,
    'loved': 0.9,
    'calm': 0.8,
    'okay': 0.6,
    'tired': 0.4,
    'sad': 0.3,
    'anxious': 0.25,
    'irritable': 0.2,
    'angry': 0.15,
    'miserable': 0.1,
  };

  final phaseScores = <String, List<double>>{
    'menstrual': [],
    'follicular': [],
    'ovulation': [],
    'luteal': [],
  };

  if (cycles.isNotEmpty) {
    for (final log in logs) {
      if (log.mood.isEmpty || log.mood == 'none') continue;
      final score = moodScore[log.mood.toLowerCase()] ?? 0.5;

      // Determine phase for this log date
      final lastCycleStart = cycles.first.startDate;
      final avgLen = prediction?.averageLength ?? 28;

      final phase = PredictionEngine.getCurrentPhase(
        lastPeriodStart: lastCycleStart,
        averageCycleLength: avgLen,
        averagePeriodLength: 5,
        nextPeriodDate: nextPeriod,
      );
      final phaseName = _phaseToKey(phase);
      phaseScores[phaseName]?.add(score);
    }
  }

  final moodByPhase = [
    _buildMoodStat('Menstrual', phaseScores['menstrual']!, '😔'),
    _buildMoodStat('Follicular', phaseScores['follicular']!, '🥰'),
    _buildMoodStat('Ovulation', phaseScores['ovulation']!, '😊'),
    _buildMoodStat('Luteal', phaseScores['luteal']!, '😐'),
  ];

  // --- Hero card -----------------------------------------------------------
  final accuracy = (nextPeriodConf * 100).round();
  String heroTitle = 'Start logging to see insights!';
  String heroSubtitle =
      'Track your period to get personalised predictions and patterns 💕';
  String heroEmoji = '🌸';

  if (cycleLengths.length >= 3) {
    final range = maxLen! - minLen!;
    if (range <= 3) {
      heroTitle = "You're beautifully regular!";
      heroSubtitle =
          'Your cycles have stayed between $minLen–$maxLen days for ${cycleLengths.length} cycles. Your AI model is $accuracy% accurate for your body 💕';
      heroEmoji = '🌿';
    } else if (range <= 7) {
      heroTitle = 'Your cycle is mostly regular';
      heroSubtitle =
          'Cycles range $minLen–$maxLen days over ${cycleLengths.length} cycles. Your prediction accuracy is $accuracy% 💕';
      heroEmoji = '🌼';
    } else {
      heroTitle = 'Your cycle is still syncing';
      heroSubtitle =
          'With more logs we\'ll find your pattern. Tracking ${cycleLengths.length} cycles so far 💕';
      heroEmoji = '🌱';
    }
  } else if (cycles.isNotEmpty) {
    heroTitle = 'Building your profile...';
    heroSubtitle =
        'Log ${3 - cycleLengths.length} more cycles to unlock accurate predictions 💕';
    heroEmoji = '🌱';
  }

  return InsightsData(
    heroTitle: heroTitle,
    heroSubtitle: heroSubtitle,
    heroEmoji: heroEmoji,
    minCycleLength: minLen,
    maxCycleLength: maxLen,
    cyclesTracked: cycles.length,
    predictionAccuracy: nextPeriodConf,
    cycleChart: cycleChart,
    topSymptoms: topSymptoms,
    nextPeriodDate: nextPeriod,
    nextPeriodConfidence: nextPeriodConf,
    fertileWindowStart: fertileRange?.start,
    fertileWindowEnd: fertileRange?.end,
    ovulationDate: ovulation,
    moodByPhase: moodByPhase,
  );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _phaseToKey(CyclePhase phase) {
  switch (phase) {
    case CyclePhase.menstruation:
      return 'menstrual';
    case CyclePhase.follicular:
      return 'follicular';
    case CyclePhase.ovulation:
      return 'ovulation';
    case CyclePhase.luteal:
      return 'luteal';
  }
}

MoodPhaseStat _buildMoodStat(String label, List<double> scores, String emoji) {
  if (scores.isEmpty) {
    // sensible OB/GYN-based defaults when no data
    final defaults = {
      'Menstrual': 0.30,
      'Follicular': 0.90,
      'Ovulation': 0.85,
      'Luteal': 0.50,
    };
    return MoodPhaseStat(label, defaults[label] ?? 0.5, emoji);
  }
  final avg = scores.reduce((a, b) => a + b) / scores.length;
  return MoodPhaseStat(label, avg, emoji);
}

String _formatSymptomName(String raw) {
  if (raw.isEmpty) return raw;
  // Convert snake_case or camelCase to Title Case
  final spaced = raw.replaceAllMapped(
      RegExp(r'_([a-z])'), (m) => ' ${m.group(1)!.toUpperCase()}');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

// ─── Symptom color helper ────────────────────────────────────────────────────

Color symptomColor(int index) {
  const colors = [
    Color(0xFFD97B8A), // rose
    Color(0xFFA880C8), // lavender
    Color(0xFF6A9E7A), // sage
    Color(0xFF5A80C0), // blue
    Color(0xFFD4936A), // amber
  ];
  return colors[index % colors.length];
}
