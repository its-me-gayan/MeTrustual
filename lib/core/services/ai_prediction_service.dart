import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/smart_cycle_detector.dart';

/// Minimum number of detected complete cycles before we call the AI.
/// Below this threshold we use the math fallback — not enough data to
/// give the AI anything meaningful to work with.
const kAiMinCycles = 1;

/// After the AI makes a prediction we store it in Firestore and treat it
/// as fresh for this many hours. Avoids re-calling the API on every app open.
const kAiCacheDurationHours = 12;

// ─────────────────────────────────────────────────────────────────────────────
// What the AI returns (parsed from JSON)
// ─────────────────────────────────────────────────────────────────────────────
class AiPredictionResult {
  /// Predicted next period date
  final DateTime nextPeriod;

  /// AI's best estimate of average cycle length
  final int cycleLength;

  /// AI's best estimate of period length
  final int periodLength;

  /// 0–100 (AI assessed)
  final int confidencePct;

  /// Short plain-language insight for the home card, e.g.
  /// "Your cycles have been shortening slightly — you may be a few days early."
  final String insight;

  /// When the AI made this prediction (for cache invalidation)
  final DateTime generatedAt;

  const AiPredictionResult({
    required this.nextPeriod,
    required this.cycleLength,
    required this.periodLength,
    required this.confidencePct,
    required this.insight,
    required this.generatedAt,
  });

  Map<String, dynamic> toFirestore() => {
        'nextPeriod': Timestamp.fromDate(nextPeriod),
        'cycleLength': cycleLength,
        'periodLength': periodLength,
        'confidencePct': confidencePct,
        'insight': insight,
        'generatedAt': Timestamp.fromDate(generatedAt),
      };

  static AiPredictionResult? fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return null;
    try {
      return AiPredictionResult(
        nextPeriod: (data['nextPeriod'] as Timestamp).toDate(),
        cycleLength: data['cycleLength'] as int,
        periodLength: data['periodLength'] as int,
        confidencePct: data['confidencePct'] as int,
        insight: data['insight'] as String,
        generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      );
    } catch (_) {
      return null;
    }
  }

  bool get isFresh {
    final age = DateTime.now().difference(generatedAt);
    return age.inHours < kAiCacheDurationHours;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────
class AiPredictionService {
  final FirebaseFirestore _firestore;
  final String _uid;

  AiPredictionService({
    required FirebaseFirestore firestore,
    required String uid,
  })  : _firestore = firestore,
        _uid = uid;

  // ── Load API key from Firestore (same pattern as Luna) ───────────────────
  Future<String?> _loadApiKey() async {
    try {
      final doc = await _firestore.collection('config').doc('anthropic').get();
      return doc.data()?['apiKey'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Load cached AI prediction from journey doc ──────────────────────────
  Future<AiPredictionResult?> loadCachedPrediction() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('journey')
          .doc('period')
          .get();
      final raw = doc.data()?['aiPrediction'] as Map<String, dynamic>?;
      return AiPredictionResult.fromFirestore(raw);
    } catch (_) {
      return null;
    }
  }

  // ── Save AI prediction back to journey doc ───────────────────────────────
  Future<void> _cachePrediction(AiPredictionResult result) async {
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('journey')
          .doc('period')
          .set({'aiPrediction': result.toFirestore()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AiPrediction] Cache write failed: $e');
    }
  }

  // ── Main entry: get prediction (from cache or fresh AI call) ────────────
  ///
  /// Returns null if:
  ///   - Not enough data (< kAiMinCycles complete cycles)
  ///   - No API key configured
  ///   - API call fails
  ///
  /// The caller should fall back to the math engine in those cases.
  Future<AiPredictionResult?> getPrediction({
    required List<DetectedCycle> detectedCycles,
    required int journeyCycleLen,
    required int journeyPeriodLen,
    required DateTime? journeyLastPeriod,
    bool forceRefresh = false,
  }) async {
    final completeCycles =
        detectedCycles.where((c) => c.cycleLength != null).toList();

    // Not enough data — let the math engine handle it
    if (completeCycles.length < kAiMinCycles) return null;

    // Check cache first
    if (!forceRefresh) {
      final cached = await loadCachedPrediction();
      if (cached != null && cached.isFresh) {
        debugPrint('[AiPrediction] Using cached prediction.');
        return cached;
      }
    }

    // Need a fresh call
    final apiKey = await _loadApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('[AiPrediction] No API key — skipping AI prediction.');
      return null;
    }

    return _callAi(
      apiKey: apiKey,
      detectedCycles: detectedCycles,
      completeCycles: completeCycles,
      journeyCycleLen: journeyCycleLen,
      journeyPeriodLen: journeyPeriodLen,
      journeyLastPeriod: journeyLastPeriod,
    );
  }

  // ── Build the AI prompt ──────────────────────────────────────────────────
  String _buildPrompt({
    required List<DetectedCycle> detectedCycles,
    required List<DetectedCycle> completeCycles,
    required int journeyCycleLen,
    required int journeyPeriodLen,
    required DateTime? journeyLastPeriod,
  }) {
    final sb = StringBuffer();

    sb.writeln('You are a menstrual cycle analysis AI. Analyze the following '
        'cycle data and return a JSON prediction. '
        'IMPORTANT: Return ONLY raw JSON — no markdown, no explanation, no backticks.\n');

    sb.writeln('== User Setup (self-reported, may be inaccurate) ==');
    sb.writeln('Reported cycle length: $journeyCycleLen days');
    sb.writeln('Reported period length: $journeyPeriodLen days');
    if (journeyLastPeriod != null) {
      sb.writeln(
          'Reported last period: ${journeyLastPeriod.toIso8601String().substring(0, 10)}');
    }

    sb.writeln('\n== Detected Cycles From Logged Data (ground truth) ==');
    sb.writeln(
        'Total detected: ${detectedCycles.length} periods, ${completeCycles.length} complete cycles\n');

    for (int i = 0; i < detectedCycles.length; i++) {
      final c = detectedCycles[i];
      final lengthStr =
          c.cycleLength != null ? '${c.cycleLength} days' : 'ongoing';
      sb.writeln(
          'Cycle ${i + 1}: started ${c.startDate.toIso8601String().substring(0, 10)}, '
          'period lasted ${c.periodDays} days, '
          'cycle length: $lengthStr');
    }

    sb.writeln(
        '\nToday\'s date: ${DateTime.now().toIso8601String().substring(0, 10)}');

    sb.writeln('''
== Your Task ==
Based on the detected cycles (trust these over the self-reported values),
predict the next period and return this JSON object:

{
  "nextPeriod": "YYYY-MM-DD",
  "cycleLength": <integer, average cycle length in days>,
  "periodLength": <integer, average period length in days>,
  "confidencePct": <integer 0-100, your confidence in this prediction>,
  "insight": "<1-2 sentences in plain warm language about what you noticed in this person's cycle pattern. Focus on trends, irregularities, or reassurance. Do NOT mention dates.>"
}

Rules:
- nextPeriod must be a real calendar date in YYYY-MM-DD format
- cycleLength and periodLength must be integers between 18 and 60
- confidencePct: use 30-50 for 1 cycle, 55-70 for 2, 70-90 for 3+
- insight must be warm, personal, under 40 words
- Return ONLY the JSON object. Nothing else.''');

    return sb.toString();
  }

  // ── Call Claude API ──────────────────────────────────────────────────────
  Future<AiPredictionResult?> _callAi({
    required String apiKey,
    required List<DetectedCycle> detectedCycles,
    required List<DetectedCycle> completeCycles,
    required int journeyCycleLen,
    required int journeyPeriodLen,
    required DateTime? journeyLastPeriod,
  }) async {
    final prompt = _buildPrompt(
      detectedCycles: detectedCycles,
      completeCycles: completeCycles,
      journeyCycleLen: journeyCycleLen,
      journeyPeriodLen: journeyPeriodLen,
      journeyLastPeriod: journeyLastPeriod,
    );

    try {
      debugPrint('[AiPrediction] Calling Claude API…');
      final res = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model':
                  'claude-haiku-4-5-20251001', // fast + cheap for prediction
              'max_tokens': 300,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        debugPrint('[AiPrediction] API error ${res.statusCode}: ${res.body}');
        return null;
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final content = (body['content'] as List?)?.firstOrNull;
      final rawText = (content as Map?)?['text'] as String?;
      if (rawText == null) return null;

      // Strip any accidental markdown fences
      final cleaned = rawText.replaceAll(RegExp(r'```json|```'), '').trim();

      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

      final nextPeriodStr = parsed['nextPeriod'] as String?;
      final nextPeriod =
          nextPeriodStr != null ? DateTime.tryParse(nextPeriodStr) : null;

      if (nextPeriod == null) {
        debugPrint('[AiPrediction] Could not parse nextPeriod from: $rawText');
        return null;
      }

      final result = AiPredictionResult(
        nextPeriod: nextPeriod,
        cycleLength:
            (parsed['cycleLength'] as num?)?.toInt() ?? journeyCycleLen,
        periodLength:
            (parsed['periodLength'] as num?)?.toInt() ?? journeyPeriodLen,
        confidencePct: (parsed['confidencePct'] as num?)?.toInt() ?? 50,
        insight: parsed['insight'] as String? ?? '',
        generatedAt: DateTime.now(),
      );

      // Cache it
      await _cachePrediction(result);
      debugPrint(
          '[AiPrediction] Prediction cached. Next: ${result.nextPeriod}, '
          'confidence: ${result.confidencePct}%');

      return result;
    } catch (e) {
      debugPrint('[AiPrediction] Exception: $e');
      return null;
    }
  }
}
