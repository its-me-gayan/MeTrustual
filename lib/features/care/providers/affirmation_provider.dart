import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/affirmation_service.dart';
import '../../../core/providers/mode_provider.dart';

// Affirmation provider - generates AI affirmation based on profile and phase
final affirmationProvider = FutureProvider.family<String, String>((ref, phase) async {
  final currentMode = ref.watch(modeProvider);
  
  try {
    final affirmation = await AffirmationService.getAffirmationOfTheDay(
      profile: currentMode,
      phase: phase,
    );
    return affirmation;
  } catch (e) {
    print('Error in affirmationProvider: $e');
    // Return a fallback affirmation
    return AffirmationService.getFallbackAffirmation(
      profile: currentMode,
      phase: phase,
    );
  }
});
