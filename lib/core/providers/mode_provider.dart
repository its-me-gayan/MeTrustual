import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_providers.dart';

final modeProvider = StateNotifierProvider<ModeNotifier, String>((ref) {
  return ModeNotifier(ref);
});

class ModeNotifier extends StateNotifier<String> {
  final Ref _ref;
  ModeNotifier(this._ref) : super('period') {
    _loadMode();
  }

  bool _hasCompletedJourney = false;
  bool get hasCompletedJourney => _hasCompletedJourney;

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('currentMode') ?? 'period';
    _hasCompletedJourney = prefs.getBool('hasCompletedJourney') ?? false;
    state = mode;
    
    // Attempt to sync from Firestore if user is logged in
    await syncFromFirestore();
  }

  Future<void> syncFromFirestore() async {
    try {
      final auth = _ref.read(firebaseAuthProvider);
      final firestore = _ref.read(firestoreProvider);
      final uid = auth.currentUser?.uid;

      if (uid != null) {
        final doc = await firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            final firestoreMode = data['currentMode'] as String?;
            final firestoreCompleted = data['hasCompletedJourney'] as bool?;
            
            if (firestoreMode != null) {
              state = firestoreMode;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('currentMode', firestoreMode);
            }
            
            if (firestoreCompleted != null) {
              _hasCompletedJourney = firestoreCompleted;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasCompletedJourney', firestoreCompleted);
            }
          }
        }
      }
    } catch (e) {
      // Silently fail, fallback to local prefs
    }
  }

  Future<void> setMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentMode', mode);
    state = mode;
    
    // Sync to Firestore
    await _syncToFirestore({'currentMode': mode});
  }

  Future<void> completeJourney() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedJourney', true);
    _hasCompletedJourney = true;
    
    // Sync to Firestore
    await _syncToFirestore({'hasCompletedJourney': true});
  }

  Future<void> resetJourney() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedJourney', false);
    _hasCompletedJourney = false;
    
    // Sync to Firestore
    await _syncToFirestore({'hasCompletedJourney': false});
  }

  Future<void> _syncToFirestore(Map<String, dynamic> data) async {
    try {
      final auth = _ref.read(firebaseAuthProvider);
      final firestore = _ref.read(firestoreProvider);
      final uid = auth.currentUser?.uid;

      if (uid != null) {
        await firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
      }
    } catch (e) {
      // Silently fail
    }
  }
}
