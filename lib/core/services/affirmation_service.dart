import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AffirmationService {
  static const String _prefixKey = 'affirmation_';
  static const String _dateKey = '_date';
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  /// Get or generate affirmation for the day based on profile and phase
  /// Returns cached affirmation if it exists for today, otherwise generates new one
  static Future<String> getAffirmationOfTheDay({
    required String profile, // 'period', 'preg', 'ovul'
    required String phase, // e.g., 'Menstrual', '1st Trim', 'Early'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_prefixKey${profile}_$phase';
    final dateKey = '$cacheKey$_dateKey';

    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Check if we have a cached affirmation for today
    final cachedDate = prefs.getString(dateKey);
    if (cachedDate == todayString) {
      final cached = prefs.getString(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    // Generate new affirmation
    final affirmation = await _generateAffirmation(profile: profile, phase: phase);

    // Cache it for today
    await prefs.setString(cacheKey, affirmation);
    await prefs.setString(dateKey, todayString);

    return affirmation;
  }

  /// Generate affirmation using OpenAI API
  static Future<String> _generateAffirmation({
    required String profile,
    required String phase,
  }) async {
    try {
      // If API key is not available, use fallback
      if (_apiKey.isEmpty) {
        return getFallbackAffirmation(profile: profile, phase: phase);
      }

      final prompt = _buildPrompt(profile: profile, phase: phase);

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4.1-mini',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.8,
          'max_tokens': 100,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          return content.trim();
        }
      }

      // Fallback if API fails
      return getFallbackAffirmation(profile: profile, phase: phase);
    } catch (e) {
      print('Error generating affirmation: $e');
      return getFallbackAffirmation(profile: profile, phase: phase);
    }
  }

  /// Build the prompt for affirmation generation
  static String _buildPrompt({
    required String profile,
    required String phase,
  }) {
    String profileContext = '';
    String phaseContext = '';

    // Profile context
    switch (profile) {
      case 'period':
        profileContext =
            'The user is tracking their menstrual cycle and wants affirmations related to cycle wellness, hormonal health, and self-care during different phases.';
        break;
      case 'preg':
        profileContext =
            'The user is pregnant and wants affirmations related to pregnancy wellness, nurturing themselves and their baby, and preparing for motherhood.';
        break;
      case 'ovul':
        profileContext =
            'The user is tracking fertility and ovulation, and wants affirmations related to fertility wellness, cycle awareness, and reproductive health.';
        break;
    }

    // Phase context
    switch (profile) {
      case 'period':
        switch (phase) {
          case 'Menstrual':
            phaseContext =
                'This is the Menstrual phase (Winter Season) - focus on rest, warmth, and gentle nourishment.';
            break;
          case 'Follicular':
            phaseContext =
                'This is the Follicular phase (Spring Season) - energy is rising, focus on planning and fresh beginnings.';
            break;
          case 'Ovulatory':
            phaseContext =
                'This is the Ovulatory phase (Summer Season) - peak energy and confidence, perfect for social connection.';
            break;
          case 'Luteal':
            phaseContext =
                'This is the Luteal phase (Autumn Season) - turn inward, focus on completion and self-care.';
            break;
        }
        break;
      case 'preg':
        switch (phase) {
          case '1st Trim':
            phaseContext = 'This is the 1st Trimester - focus on nurturing the seed and managing early pregnancy changes.';
            break;
          case '2nd Trim':
            phaseContext = 'This is the 2nd Trimester (Golden Phase) - focus on bonding and baby preparation.';
            break;
          case '3rd Trim':
            phaseContext = 'This is the 3rd Trimester (Home Stretch) - focus on preparation and managing discomfort.';
            break;
          case 'Newborn':
            phaseContext = 'This is the Postpartum/4th Trimester - focus on healing, recovery, and bonding.';
            break;
        }
        break;
      case 'ovul':
        switch (phase) {
          case 'Early':
            phaseContext = 'This is the Early phase - laying groundwork and focusing on baseline health.';
            break;
          case 'Pre-Ovul':
            phaseContext = 'This is the Pre-Ovulation phase - energy is rising and body is preparing.';
            break;
          case 'Peak':
            phaseContext = 'This is the Peak/Ovulation phase - the key moment of the cycle.';
            break;
          case 'Post-Ovul':
            phaseContext = 'This is the Post-Ovulation phase - the implantation window, focus on calm and warmth.';
            break;
        }
        break;
    }

    return '''Generate a short, powerful, and personalized affirmation for a woman.

Context:
$profileContext
$phaseContext

Requirements:
- The affirmation should be 1-2 sentences maximum
- It should be positive, empowering, and relevant to the phase
- It should feel personal and resonate with the user's wellness journey
- Use "I" statements (e.g., "I am...", "I honor...", "I trust...")
- Avoid generic affirmations - make it specific to the phase and profile
- Do NOT include emojis or quotes around the affirmation

Generate only the affirmation text, nothing else.''';
  }

  /// Get fallback affirmation when API is unavailable
  static String getFallbackAffirmation({
    required String profile,
    required String phase,
  }) {
    final fallbacks = {
      'period': {
        'Menstrual': 'I honor my body\'s need for rest and give myself permission to slow down.',
        'Follicular': 'My energy is rising, and I embrace fresh beginnings with confidence.',
        'Ovulatory': 'I radiate strength and celebrate my peak vitality today.',
        'Luteal': 'I turn inward with compassion and nurture myself with gentle care.',
      },
      'preg': {
        '1st Trim': 'My body knows exactly how to nurture this precious life within me.',
        '2nd Trim': 'I feel the glow of this golden phase and celebrate the journey ahead.',
        '3rd Trim': 'I am strong, prepared, and ready for the beautiful arrival ahead.',
        'Newborn': 'I am healing, bonding, and learning to trust my instincts as a mother.',
      },
      'ovul': {
        'Early': 'I lay the groundwork for my fertility with awareness and intention.',
        'Pre-Ovul': 'My body is preparing, and I trust the wisdom of my natural rhythm.',
        'Peak': 'This is my moment of peak fertility, and I honor the power within me.',
        'Post-Ovul': 'I support my body with calm, warmth, and mindful presence.',
      },
    };

    return fallbacks[profile]?[phase] ?? 'I am exactly where I need to be in my cycle.';
  }
}
