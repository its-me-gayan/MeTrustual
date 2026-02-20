import 'dart:math';
import 'package:flutter/material.dart';

enum CyclePhase { menstruation, follicular, ovulation, luteal }

class PredictionResult {
  final DateTime date;
  final double confidence;
  final int averageLength;

  PredictionResult({
    required this.date,
    required this.confidence,
    required this.averageLength,
  });
}

class PredictionEngine {
  static PredictionResult predictNextPeriod({
    required DateTime lastPeriodStart,
    required List<int> cycleLengths,
  }) {
    if (cycleLengths.isEmpty) {
      return PredictionResult(
        date: lastPeriodStart.add(const Duration(days: 28)),
        confidence: 0.5,
        averageLength: 28,
      );
    }

    final weights = List.generate(cycleLengths.length, (i) => i + 1.0);
    final totalWeight = weights.reduce((a, b) => a + b);
    final weightedAvg = cycleLengths.asMap().entries
            .map((e) => e.value * weights[e.key])
            .reduce((a, b) => a + b) /
        totalWeight;

    final mean = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    final variance = cycleLengths
            .map((x) => pow(x - mean, 2))
            .reduce((a, b) => a + b) /
        cycleLengths.length;
    final stdDev = sqrt(variance);

    final dataConfidence = min(cycleLengths.length / 6.0, 1.0);
    final regularityConfidence = max(0.0, 1.0 - (stdDev / 7.0));
    final confidence = (dataConfidence * 0.4) + (regularityConfidence * 0.6);

    return PredictionResult(
      date: lastPeriodStart.add(Duration(days: weightedAvg.round())),
      confidence: confidence,
      averageLength: weightedAvg.round(),
    );
  }

  static DateTimeRange predictFertileWindow({
    required DateTime nextPeriodDate,
    required int averageCycleLength,
  }) {
    final ovulationDate = nextPeriodDate.subtract(const Duration(days: 14));
    return DateTimeRange(
      start: ovulationDate.subtract(const Duration(days: 5)),
      end: ovulationDate.add(const Duration(days: 1)),
    );
  }

  static CyclePhase getCurrentPhase({
    required DateTime lastPeriodStart,
    required int averageCycleLength,
    required int averagePeriodLength,
  }) {
    final daysSincePeriod = DateTime.now().difference(lastPeriodStart).inDays + 1;

    if (daysSincePeriod <= averagePeriodLength) return CyclePhase.menstruation;
    if (daysSincePeriod <= (averageCycleLength / 2 - 2)) return CyclePhase.follicular;
    if (daysSincePeriod <= (averageCycleLength / 2 + 2)) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }
}
