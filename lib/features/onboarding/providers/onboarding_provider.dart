import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/uuid_persistence_service.dart';
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
    String nickname = 'Sweetie',
  }) async {
    final auth = _ref.read(firebaseAuthProvider);
    final firestore = _ref.read(firestoreProvider);

    // 1. Create anonymous user
    final userCredential = await auth.signInAnonymously();
    final user = userCredential.user!;
    final uid = user.uid;

    // Update display name in Firebase Auth
    await user.updateDisplayName(nickname);

    // 2. Save settings to Firestore
    await firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('current')
        .set({
      'anonymousMode': anonymousMode,
      'cloudSync': cloudSync,
      'biometricLock': true,
      'discreteMode': false,
      'consentAnalytics': true,
      'consentAI': true,
      'reminderPeriod': true,
      'reminderDaily': true,
      'theme': 'light',
      'language': language,
    });

    // 3. Create initial profile
    final profile = UserProfile(
      uid: uid,
      displayName: nickname,
      ageGroup: 'adult',
      region: 'global',
      language: language,
      createdAt: DateTime.now(),
      lifeStage: 'tracking',
    );
    await firestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('current')
        .set(profile.toFirestore());

    // 4. Save UUID to local and secure storage
    await UUIDPersistenceService.saveUUID(uid);

    // 5. Create local backup
    if (!anonymousMode || cloudSync) {
      await BackupService.createLocalBackup(
        uid: uid,
        userData: {
          'profile': profile.toFirestore(),
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      // Backup UUID to cloud
      if (cloudSync) {
        await UUIDPersistenceService.backupUUIDToCloud(uid);
        await BackupService.backupToCloud(
          uid: uid,
          backupData: {'profile': profile.toFirestore()},
        );
      }
    }

    // 6. Save local state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasOnboarded', true);
    await prefs.setString('language', language);
    await prefs.setBool('anonymousMode', anonymousMode);
    await prefs.setBool('cloudSync', cloudSync);
    await prefs.setString('nickname', nickname);

    state = true;
  }
}
