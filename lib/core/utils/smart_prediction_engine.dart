import 'dart:math';
import 'smart_cycle_detector.dart';

/// Which data source is driving the current prediction.
/// Used by the UI to show appropriate confidence messaging.
enum PredictionSource {
  /// Only the journey answers are available — user self-reported, low trust
  journeySeed,

  /// 1 real cycle detected — blending journey + real data
  learning,

  /// 2+ real cycles detected — mostly real data, higher trust
  building,

  /// 3+ real cycles detected — fully data-driven
  confident,
}

class SmartPredictionResult {
  /// Predicted next period date
  final DateTime nextPeriod;

  /// Best estimate of cycle length (days)
  final int cycleLength;

  /// Best estimate of period length (days)
  final int periodLength;

  /// 0.0 – 1.0
  final double confidence;

  /// What's driving this prediction
  final PredictionSource source;

  /// How many real cycles were used
  final int realCyclesUsed;

  /// Short label for the UI, e.g. "Based on 3 logged cycles"
  final String sourceLabel;

  const SmartPredictionResult({
    required this.nextPeriod,
    required this.cycleLength,
    required this.periodLength,
    required this.confidence,
    required this.source,
    required this.realCyclesUsed,
    required this.sourceLabel,
  });
}

class SmartPredictionEngine {
  // ─────────────────────────────────────────────────────────────────────────
  // How many logged cycles are needed to reach each stage
  // ─────────────────────────────────────────────────────────────────────────
  static const _learningThreshold = 1; // at least 1 complete cycle
  static const _buildingThreshold = 2;
  static const _confidentThreshold = 3;

  // ─────────────────────────────────────────────────────────────────────────
  // Main prediction method
  // ─────────────────────────────────────────────────────────────────────────

  /// [detectedCycles]    — output of SmartCycleDetector.detect()
  /// [journeyCycleLen]   — user's self-reported cycle length (journey answer)
  /// [journeyPeriodLen]  — user's self-reported period length (journey answer)
  /// [journeyLastPeriod] — user's self-reported last period date (journey answer)
  static SmartPredictionResult predict({
    required List<DetectedCycle> detectedCycles,
    required int journeyCycleLen,
    required int journeyPeriodLen,
    required DateTime? journeyLastPeriod,
  }) {
    // Complete cycles = cycles where we know the full length
    final completeCycles =
        detectedCycles.where((c) => c.cycleLength != null).toList();

    final realCount = completeCycles.length;

    // ── Stage 0: no real data yet ─────────────────────────────────────────
    if (realCount == 0) {
      return _seedResult(
        journeyCycleLen: journeyCycleLen,
        journeyPeriodLen: journeyPeriodLen,
        journeyLastPeriod: journeyLastPeriod,
        // If we detected a period start from logs (but no complete cycle yet),
        // use that as the more accurate "last period" anchor
        detectedLastPeriod:
            SmartCycleDetector.mostRecentPeriodStart(detectedCycles),
      );
    }

    // ── Extract real cycle lengths (most recent first for weighting) ───────
    final realLengths = completeCycles
        .map((c) => c.cycleLength!)
        .toList()
        .reversed
        .toList(); // newest first

    // ── Compute weighted average of real cycles ────────────────────────────
    // More recent cycles get higher weight
    final realAvg = _weightedAverage(realLengths);

    // ── Blend with journey seed depending on stage ─────────────────────────
    final double blendedCycleLen;
    final PredictionSource source;
    final double confidence;

    if (realCount < _buildingThreshold) {
      // Stage 1 — learning: 60% real, 40% journey
      blendedCycleLen = (realAvg * 0.6) + (journeyCycleLen * 0.4);
      source = PredictionSource.learning;
      confidence = 0.55;
    } else if (realCount < _confidentThreshold) {
      // Stage 2 — building: 80% real, 20% journey
      blendedCycleLen = (realAvg * 0.8) + (journeyCycleLen * 0.2);
      source = PredictionSource.building;
      confidence = 0.70;
    } else {
      // Stage 3 — confident: 100% real data + regularity bonus
      blendedCycleLen = realAvg;
      source = PredictionSource.confident;
      confidence = _confidenceFromRegularity(realLengths);
    }

    // ── Period length: prefer detected average if enough data ─────────────
    final detectedPeriodLen =
        SmartCycleDetector.averagePeriodLength(detectedCycles);
    final int periodLen =
        detectedPeriodLen != null && detectedCycles.length >= 2
            ? detectedPeriodLen.round()
            : journeyPeriodLen;

    // ── Most accurate "last period" anchor ────────────────────────────────
    // Detected last period from logs > journey self-report
    final lastPeriodAnchor =
        SmartCycleDetector.mostRecentPeriodStart(detectedCycles) ??
            journeyLastPeriod;

    if (lastPeriodAnchor == null) {
      // No anchor at all — fall back to seed
      return _seedResult(
        journeyCycleLen: journeyCycleLen,
        journeyPeriodLen: journeyPeriodLen,
        journeyLastPeriod: null,
        detectedLastPeriod: null,
      );
    }

    final nextPeriod =
        lastPeriodAnchor.add(Duration(days: blendedCycleLen.round()));

    return SmartPredictionResult(
      nextPeriod: nextPeriod,
      cycleLength: blendedCycleLen.round(),
      periodLength: periodLen,
      confidence: confidence,
      source: source,
      realCyclesUsed: realCount,
      sourceLabel: _sourceLabel(source, realCount),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stage 0: pure journey-seed result
  // ─────────────────────────────────────────────────────────────────────────
  static SmartPredictionResult _seedResult({
    required int journeyCycleLen,
    required int journeyPeriodLen,
    required DateTime? journeyLastPeriod,
    required DateTime? detectedLastPeriod,
  }) {
    // Use detected last period if available (more accurate than self-report)
    final anchor = detectedLastPeriod ?? journeyLastPeriod;

    // If still no anchor at all we can't predict — return a placeholder
    final nextPeriod = anchor != null
        ? anchor.add(Duration(days: journeyCycleLen))
        : DateTime.now().add(Duration(days: journeyCycleLen));

    return SmartPredictionResult(
      nextPeriod: nextPeriod,
      cycleLength: journeyCycleLen,
      periodLength: journeyPeriodLen,
      confidence: anchor != null ? 0.35 : 0.20,
      source: PredictionSource.journeySeed,
      realCyclesUsed: 0,
      sourceLabel: _sourceLabel(PredictionSource.journeySeed, 0),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Weighted average: index 0 (newest) gets weight N, index N-1 gets weight 1
  static double _weightedAverage(List<int> values) {
    if (values.isEmpty) return 28;
    final n = values.length;
    double weightedSum = 0;
    double totalWeight = 0;
    for (int i = 0; i < n; i++) {
      final weight = (n - i).toDouble(); // newer = higher weight
      weightedSum += values[i] * weight;
      totalWeight += weight;
    }
    return weightedSum / totalWeight;
  }

  /// Higher confidence when cycles are more regular (low std dev)
  static double _confidenceFromRegularity(List<int> lengths) {
    if (lengths.length < 2) return 0.75;
    final mean = lengths.reduce((a, b) => a + b) / lengths.length;
    final variance = lengths
            .map((x) => pow(x - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        lengths.length;
    final stdDev = sqrt(variance);
    // stdDev of 0 → 0.95 confidence, stdDev of 7 → 0.50 confidence
    return (max(0.50, 0.95 - (stdDev / 14))).clamp(0.50, 0.95);
  }

  static String _sourceLabel(PredictionSource source, int realCount) {
    switch (source) {
      case PredictionSource.journeySeed:
        return 'Based on your setup answers · Log more to improve';
      case PredictionSource.learning:
        return 'Based on 1 logged cycle · Still learning…';
      case PredictionSource.building:
        return 'Based on $realCount logged cycles · Getting accurate';
      case PredictionSource.confident:
        return 'Based on $realCount logged cycles · High accuracy';
    }
  }
}
