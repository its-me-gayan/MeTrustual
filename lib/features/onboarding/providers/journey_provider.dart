import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/firebase_providers.dart';

// Provider to load journey steps from Firestore
final journeyStepsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, mode) async {
  final firestore = ref.read(firestoreProvider);

  try {
    final doc = await firestore.collection('journeys').doc(mode).get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['steps'] != null) {
        final steps = List<Map<String, dynamic>>.from(data['steps']);
        return steps;
      }
    }

    // Fallback to empty list if document doesn't exist
    return [];
  } catch (e) {
    debugPrint('Error loading journey steps for mode $mode: $e');
    return [];
  }
});

// Provider to get journey steps with fallback to hardcoded values
final journeyStepsWithFallbackProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, mode) async {
  final firestore = ref.read(firestoreProvider);

  try {
    final doc = await firestore.collection('journeys').doc(mode).get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['steps'] != null) {
        final steps = List<Map<String, dynamic>>.from(data['steps']);
        return steps;
      }
    }
  } catch (e) {
    debugPrint('Error loading journey steps from Firestore: $e');
  }

  // Fallback to hardcoded values if Firestore fails
  return _getHardcodedJourneySteps(mode);
});

// Hardcoded journey steps as fallback
List<Map<String, dynamic>> _getHardcodedJourneySteps(String mode) {
  if (mode == 'preg') {
    return [
      {
        'icon': '🤰',
        'q': 'Are you currently pregnant?',
        'sub':
            'This helps us set up the right tracker for you. No judgement either way.',
        'type': 'chips-big-single',
        'key': 'isPreg',
        'required': true,
        'opts': [
          {'e': '✅', 'l': "Yes, I'm pregnant!", 'v': 'yes'},
          {'e': '🤔', 'l': 'I think I might be', 'v': 'maybe'},
          {
            'e': '🔄',
            'l': "Actually, I'm not — switch tracker",
            'v': 'switch',
            'special': true
          }
        ],
        'warn':
            'You can switch back to Period or Ovulation tracker anytime from your home screen.'
      },
      {
        'icon': '📅',
        'q': 'Do you know your due date?',
        'sub':
            'If yes, enter it. If not, enter your last period start date and we\'ll calculate.',
        'type': 'due-date',
        'key': 'dueDate',
        'required': false,
      },
      {
        'icon': '👶',
        'q': 'Is this your first pregnancy?',
        'sub': 'This personalises your week-by-week tips and what to expect.',
        'type': 'chips-big-single',
        'key': 'firstPreg',
        'required': true,
        'opts': [
          {'e': '🌱', 'l': 'Yes — my first!', 'v': 'first'},
          {'e': '👧', 'l': 'I have one child', 'v': 'second'},
          {'e': '👨‍👩‍👧‍👦', 'l': 'Two or more children', 'v': 'multiple'}
        ]
      },
      {
        'icon': '🩺',
        'q': 'Any conditions to track together?',
        'sub':
            'Optional — select any for extra personalised support and reminders.',
        'type': 'chips-multi',
        'key': 'conditions',
        'opts': [
          {'e': '🩺', 'l': 'Gestational Diabetes'},
          {'e': '💓', 'l': 'High Blood Pressure'},
          {'e': '🤢', 'l': 'Severe Morning Sickness'},
          {'e': '🩸', 'l': 'Anaemia'},
          {'e': '🧠', 'l': 'Prenatal Anxiety'},
          {'e': '😴', 'l': 'Sleep Issues'},
          {'e': '✨', 'l': 'All good — none'}
        ]
      },
      {
        'icon': '💙',
        'q': 'What support do you want from us?',
        'sub': 'We\'ll send you the content that matters most. Adjust anytime.',
        'type': 'chips-multi',
        'key': 'support',
        'opts': [
          {'e': '📋', 'l': 'Weekly baby updates'},
          {'e': '🩺', 'l': 'Appointment reminders'},
          {'e': '👶', 'l': 'Kick counter alerts'},
          {'e': '🌿', 'l': 'Nutrition & wellness tips'},
          {'e': '🧘', 'l': 'Mental health & mindfulness'},
          {'e': '📖', 'l': 'Birth & newborn prep'}
        ]
      }
    ];
  } else if (mode == 'ovul') {
    return [
      {
        'icon': '🌿',
        'q': 'What\'s your main goal?',
        'sub':
            'This shapes your insights, alerts, and what tools we highlight for you.',
        'type': 'chips-big-single',
        'key': 'goal',
        'required': true,
        'opts': [
          {'e': '👶', 'l': 'Trying to conceive (TTC)', 'v': 'ttc'},
          {'e': '🌿', 'l': 'Natural family planning', 'v': 'nfp'},
          {'e': '🔬', 'l': 'Understanding my body & cycle', 'v': 'understand'}
        ]
      },
      {
        'icon': '📅',
        'q': 'When did your last period start?',
        'sub':
            'We calculate your fertile window from this. Ovulation is usually ~14 days before your next period.',
        'type': 'date',
        'key': 'lastPeriod',
        'required': true,
        'skip': 'Skip for now'
      },
      {
        'icon': '🔁',
        'q': 'How long is your cycle usually?',
        'sub': 'Knowing this makes ovulation predictions much more accurate.',
        'type': 'stepper',
        'key': 'cycleLen',
        'min': 18,
        'max': 45,
        'def': 28,
        'unit': 'days',
        'skip': 'Not sure yet'
      },
      {
        'icon': '🌡️',
        'q': 'What do you currently track?',
        'sub':
            'Select all that apply — we\'ll guide you on using each method together.',
        'type': 'chips-multi',
        'key': 'methods',
        'opts': [
          {'e': '🌡️', 'l': 'BBT (Basal Body Temp)'},
          {'e': '💊', 'l': 'OPK / LH Test Strips'},
          {'e': '💧', 'l': 'Cervical Mucus'},
          {'e': '📅', 'l': 'Period dates only'},
          {'e': '🩸', 'l': 'Mid-cycle spotting'},
          {'e': '🆕', 'l': 'Nothing yet — just starting!'}
        ]
      },
      {
        'icon': '🔔',
        'q': 'How should we alert you?',
        'sub': 'We only send what you choose. You can change this anytime.',
        'type': 'chips-multi',
        'key': 'alerts',
        'opts': [
          {'e': '🟢', 'l': 'Fertile window opens'},
          {'e': '🎯', 'l': 'Peak ovulation day'},
          {'e': '📉', 'l': 'Fertile window closing'},
          {'e': '📅', 'l': 'Period due reminder'},
          {'e': '🌡️', 'l': 'BBT reminder each morning'},
          {'e': '💊', 'l': 'OPK test reminder'}
        ]
      }
    ];
  } else {
    // Default period mode
    return [
      {
        'icon': '🩸',
        'q': 'When did your last period start?',
        'sub':
            'This helps us predict your next period and fertile window accurately.',
        'type': 'date',
        'key': 'lastPeriod',
        'required': false,
        'skip': 'Not sure / this is my first time tracking'
      },
      {
        'icon': '📅',
        'q': 'How long is your cycle usually?',
        'sub':
            'Day 1 of one period to Day 1 of the next. Most cycles are 21–35 days.',
        'type': 'stepper',
        'key': 'cycleLen',
        'min': 18,
        'max': 45,
        'def': 28,
        'unit': 'days',
        'skip': 'Not sure yet — we\'ll learn!'
      },
      {
        'icon': '🗓️',
        'q': 'How many days does your period last?',
        'sub': 'Include light spotting days. Most periods last 3–7 days.',
        'type': 'stepper',
        'key': 'periodLen',
        'min': 1,
        'max': 10,
        'def': 5,
        'unit': 'days'
      },
      {
        'icon': '💧',
        'q': 'How would you describe your usual flow?',
        'sub':
            'Helps us give you better predictions and product recommendations.',
        'type': 'chips-single',
        'key': 'flow',
        'required': true,
        'opts': [
          {'e': '💧', 'l': 'Light', 'v': 'light'},
          {'e': '🟠', 'l': 'Medium', 'v': 'medium'},
          {'e': '🔴', 'l': 'Heavy', 'v': 'heavy'},
          {'e': '🔀', 'l': 'Varies', 'v': 'varies'}
        ]
      },
      {
        'icon': '🌀',
        'q': 'Symptoms you often get?',
        'sub':
            'Select all that apply — we\'ll personalise your care tips each phase.',
        'type': 'chips-multi',
        'key': 'symptoms',
        'opts': [
          {'e': '🌀', 'l': 'Cramps'},
          {'e': '🤕', 'l': 'Headache'},
          {'e': '😴', 'l': 'Fatigue'},
          {'e': '🤢', 'l': 'Nausea'},
          {'e': '🌊', 'l': 'Bloating'},
          {'e': '💆', 'l': 'Back Pain'},
          {'e': '🍫', 'l': 'Cravings'},
          {'e': '😤', 'l': 'Mood Swings'},
          {'e': '✨', 'l': 'None of these'}
        ]
      }
    ];
  }
}
