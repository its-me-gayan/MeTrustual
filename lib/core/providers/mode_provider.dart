import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final modeProvider = StateNotifierProvider<ModeNotifier, String>((ref) {
  return ModeNotifier();
});

class ModeNotifier extends StateNotifier<String> {
  ModeNotifier() : super('period') {
    _loadMode();
  }

  bool _hasCompletedJourney = false;
  bool get hasCompletedJourney => _hasCompletedJourney;

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('currentMode') ?? 'period';
    _hasCompletedJourney = prefs.getBool('hasCompletedJourney') ?? false;
    state = mode;
  }

  Future<void> setMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentMode', mode);
    state = mode;
  }

  Future<void> completeJourney() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedJourney', true);
    _hasCompletedJourney = true;
  }

  Future<void> resetJourney() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedJourney', false);
    _hasCompletedJourney = false;
  }
}
