import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_profile_model.dart';

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final Ref _ref;
  OnboardingNotifier(this._ref) : super(false);

  Future<void> completeOnboarding({
    required String language,
    required bool anonymousMode,
    required bool cloudSync,
  }) async {
    // TODO: Initialize Firebase and enable these calls
    // final auth = _ref.read(firebaseAuthProvider);
    // final firestore = _ref.read(firestoreProvider);

    // // 1. Create anonymous user
    // final userCredential = await auth.signInAnonymously();
    // final uid = userCredential.user!.uid;

    // // 2. Save settings to Firestore
    // await firestore.collection('users').doc(uid).collection('settings').doc('current').set({
    //   'anonymousMode': anonymousMode,
    //   'cloudSync': cloudSync,
    //   'biometricLock': true,
    //   'discreteMode': false,
    //   'consentAnalytics': true,
    //   'consentAI': true,
    //   'reminderPeriod': true,
    //   'reminderDaily': true,
    //   'theme': 'light',
    //   'language': language,
    // });

    // // 3. Create initial profile
    // final profile = UserProfile(
    //   uid: uid,
    //   displayName: 'Lovely User',
    //   ageGroup: 'adult',
    //   region: 'global',
    //   language: language,
    //   createdAt: DateTime.now(),
    //   lifeStage: 'tracking',
    // );
    // await firestore.collection('users').doc(uid).collection('profile').doc('current').set(profile.toFirestore());

    // 4. Save local state (this works without Firebase)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasOnboarded', true);
    await prefs.setString('language', language);
    await prefs.setBool('anonymousMode', anonymousMode);
    await prefs.setBool('cloudSync', cloudSync);

    state = true;
  }
}
