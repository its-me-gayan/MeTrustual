import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/biometric_service.dart';
import 'firebase_providers.dart';
import 'app_config_provider.dart'; // 👈 import your new provider

final securityProvider =
    StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  return SecurityNotifier(ref);
});

class SecurityState {
  final bool isPinSet;
  final bool isBiometricAvailable;
  final bool isVerified;
  final String? errorMessage;
  final int failedAttempts;
  final bool isLocked;
  final DateTime? lockUntil;

  SecurityState({
    this.isPinSet = false,
    this.isBiometricAvailable = false,
    this.isVerified = false,
    this.errorMessage,
    this.failedAttempts = 0,
    this.isLocked = false,
    this.lockUntil,
  });

  SecurityState copyWith({
    bool? isPinSet,
    bool? isBiometricAvailable,
    bool? isVerified,
    String? errorMessage,
    bool clearError = false,
    int? failedAttempts,
    bool? isLocked,
    DateTime? lockUntil,
    bool clearLockUntil = false,
  }) {
    return SecurityState(
      isPinSet: isPinSet ?? this.isPinSet,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      isLocked: isLocked ?? this.isLocked,
      lockUntil: clearLockUntil ? null : lockUntil ?? this.lockUntil,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  final Ref _ref;

  // ── SharedPreferences keys ──────────────────────────────────
  static const String _prefFailedAttempts = 'sec_failed_attempts';
  static const String _prefLockUntil = 'sec_lock_until';

  // ── Hardcoded fallbacks (used only if Firestore config is unavailable) ──
  static const int _fallbackMaxFailedAttempts = 5;
  static const int _fallbackLockoutDurationMinutes = 15;

  SecurityNotifier(this._ref) : super(SecurityState()) {
    _initialize();
  }

  // ── Dynamic config getters ──────────────────────────────────

  /// Max failed attempts before lockout — pulled from globalAppConfig.
  /// Falls back to [_fallbackMaxFailedAttempts] if config is unavailable.
  int get _maxFailedAttempts {
    return _ref.read(appConfigProvider).valueOrNull?.maxFailedAttempts ??
        _fallbackMaxFailedAttempts;
  }

  /// Lockout duration — pulled from globalAppConfig.
  /// Falls back to [_fallbackLockoutDurationMinutes] if config is unavailable.
  Duration get _lockoutDuration {
    final mins =
        _ref.read(appConfigProvider).valueOrNull?.lockoutDurationMinutes ??
            _fallbackLockoutDurationMinutes;
    return Duration(minutes: mins);
  }

  // ── Init — restore lockout state on every app start ────────
  Future<void> _initialize() async {
    // Warm up the remote config cache first so _maxFailedAttempts and
    // _lockoutDuration are ready before any PIN verification happens.
    await _ref
        .read(appConfigProvider.future)
        .catchError((_) => const AppConfig());

    final isBioAvailable = await BiometricService.isBiometricAvailable();
    final isPinSet = await BiometricService.isBiometricSetUp();

    // Step 1 — check SharedPreferences first (fast, local)
    final prefs = await SharedPreferences.getInstance();
    final savedAttempts = prefs.getInt(_prefFailedAttempts) ?? 0;
    final lockUntilMs = prefs.getInt(_prefLockUntil);

    bool isLocked = false;
    DateTime? lockUntil;
    String? errorMessage;

    if (lockUntilMs != null) {
      lockUntil = DateTime.fromMillisecondsSinceEpoch(lockUntilMs);
      if (DateTime.now().isBefore(lockUntil)) {
        isLocked = true;
        final remaining = lockUntil.difference(DateTime.now());
        final mins = remaining.inMinutes;
        final secs = remaining.inSeconds % 60;
        errorMessage = 'Try again in ${mins > 0 ? '$mins min' : '${secs}s'}.';
      } else {
        // Expired locally — clear
        await _clearLockout();
        lockUntil = null;
      }
    }

    // Step 2 — if not locked locally, check Firestore (covers reinstall)
    if (!isLocked) {
      try {
        final auth = _ref.read(firebaseAuthProvider);
        final uid = auth.currentUser?.uid;
        if (uid != null) {
          final firestore = _ref.read(firestoreProvider);
          final doc = await firestore.collection('users').doc(uid).get();
          final secData = doc.data()?['security'] as Map<String, dynamic>?;

          if (secData != null) {
            final cloudLockUntil = secData['lockUntil'] as Timestamp?;
            final cloudAttempts = secData['failedAttempts'] as int? ?? 0;

            if (cloudLockUntil != null) {
              final lockDate = cloudLockUntil.toDate();
              if (DateTime.now().isBefore(lockDate)) {
                // Still locked in cloud — restore
                isLocked = true;
                lockUntil = lockDate;
                final remaining = lockDate.difference(DateTime.now());
                final mins = remaining.inMinutes;
                final secs = remaining.inSeconds % 60;
                errorMessage =
                    'Try again in ${mins > 0 ? '$mins min' : '${secs}s'}.';

                // Sync back to local prefs
                await prefs.setInt(_prefFailedAttempts, cloudAttempts);
                await prefs.setInt(
                    _prefLockUntil, lockDate.millisecondsSinceEpoch);
              }
            }
          }
        }
      } catch (e) {
        // Silently fail — local state is the fallback
      }
    }

    state = state.copyWith(
      isBiometricAvailable: isBioAvailable,
      isPinSet: isPinSet,
      failedAttempts: isLocked ? savedAttempts : 0,
      isLocked: isLocked,
      lockUntil: lockUntil,
      errorMessage: errorMessage,
    );
  }

  // ── Persist lockout to SharedPreferences + Firestore ───────
  Future<void> _persistLockout(int attempts, DateTime? lockUntil) async {
    // Local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefFailedAttempts, attempts);
    if (lockUntil != null) {
      await prefs.setInt(_prefLockUntil, lockUntil.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_prefLockUntil);
    }

    // Cloud
    try {
      final auth = _ref.read(firebaseAuthProvider);
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        final firestore = _ref.read(firestoreProvider);
        await firestore.collection('users').doc(uid).set({
          'security': {
            'failedAttempts': attempts,
            'lockUntil':
                lockUntil != null ? Timestamp.fromDate(lockUntil) : null,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Silently fail
    }
  }

  // ── Clear lockout from SharedPreferences + Firestore ───────
  Future<void> _clearLockout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefFailedAttempts);
    await prefs.remove(_prefLockUntil);

    try {
      final auth = _ref.read(firebaseAuthProvider);
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        final firestore = _ref.read(firestoreProvider);
        await firestore.collection('users').doc(uid).set({
          'security': {
            'failedAttempts': 0,
            'lockUntil': null,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Silently fail
    }
  }

  // ── Check if currently locked ───────────────────────────────
  bool _checkAndUpdateLockout() {
    if (state.isLocked && state.lockUntil != null) {
      if (DateTime.now().isBefore(state.lockUntil!)) {
        final remaining = state.lockUntil!.difference(DateTime.now());
        final mins = remaining.inMinutes;
        final secs = remaining.inSeconds % 60;
        state = state.copyWith(
          errorMessage:
              'Too many failed attempts. Try again in ${mins > 0 ? '$mins min' : '${secs}s'}.',
        );
        return true;
      } else {
        // Expired — unlock
        _clearLockout();
        state = state.copyWith(
          isLocked: false,
          failedAttempts: 0,
          clearLockUntil: true,
          clearError: true,
        );
        return false;
      }
    }
    return false;
  }

  // ── Handle a failed attempt ─────────────────────────────────
  Future<void> _handleFailedAttempt() async {
    final newAttempts = state.failedAttempts + 1;
    final maxAttempts = _maxFailedAttempts; // 👈 dynamic from globalAppConfig
    final isNowLocked = newAttempts >= maxAttempts;
    final lockUntil = isNowLocked ? DateTime.now().add(_lockoutDuration) : null;

    await _persistLockout(newAttempts, lockUntil);

    state = state.copyWith(
      failedAttempts: newAttempts,
      isLocked: isNowLocked,
      lockUntil: lockUntil,
      errorMessage: isNowLocked
          ? 'Too many failed attempts. Try again in ${_lockoutDuration.inMinutes} minutes.'
          : 'Incorrect PIN. ${maxAttempts - newAttempts} attempts remaining.',
    );
  }

  // ── PIN hashing helpers ─────────────────────────────────────
  Map<String, String> _generatePinHash(String pin) {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    return {'hash': hash, 'salt': salt};
  }

  String _generateSalt() => DateTime.now().millisecondsSinceEpoch.toString();

  String _hashPin(String pin, String salt) =>
      sha256.convert(utf8.encode('$pin$salt')).toString();

  // ── Set PIN ─────────────────────────────────────────────────
  Future<bool> setPinForNewUser(String pin, String confirmPin) async {
    try {
      if (pin.isEmpty || pin.length < 4) {
        state = state.copyWith(errorMessage: 'PIN must be at least 4 digits');
        return false;
      }
      if (pin != confirmPin) {
        state = state.copyWith(errorMessage: 'PINs do not match');
        return false;
      }

      final success = await BiometricService.setBiometricPin(pin);
      if (!success) {
        state = state.copyWith(errorMessage: 'Failed to save PIN');
        return false;
      }

      final auth = _ref.read(firebaseAuthProvider);
      if (auth.currentUser != null && !auth.currentUser!.isAnonymous) {
        await _syncPinToCloud(pin, auth.currentUser!.uid);
      }

      state = state.copyWith(isPinSet: true, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error setting PIN: $e');
      return false;
    }
  }

  Future<void> _syncPinToCloud(String pin, String uid) async {
    try {
      final firestore = _ref.read(firestoreProvider);
      final hashData = _generatePinHash(pin);
      await firestore.collection('users').doc(uid).set({
        'pinHash': hashData['hash'],
        'pinSalt': hashData['salt'],
        'pinSetAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error syncing PIN to cloud: $e');
    }
  }

  // ── Verify PIN with cloud fallback ──────────────────────────
  Future<bool> verifyPinWithCloudFallback(String pin) async {
    try {
      if (_checkAndUpdateLockout()) return false;

      // Local check first
      final localVerified = await BiometricService.verifyWithPin(pin);
      if (localVerified) {
        await _clearLockout();
        state = state.copyWith(
            isVerified: true, failedAttempts: 0, clearError: true);
        return true;
      }

      // Cloud fallback
      final auth = _ref.read(firebaseAuthProvider);
      if (auth.currentUser != null && !auth.currentUser!.isAnonymous) {
        final firestore = _ref.read(firestoreProvider);
        final doc = await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .get();

        if (doc.exists) {
          final cloudHash = doc.data()?['pinHash'] as String?;
          final cloudSalt = doc.data()?['pinSalt'] as String?;
          if (cloudHash != null && cloudSalt != null) {
            if (_hashPin(pin, cloudSalt) == cloudHash) {
              await _clearLockout();
              state = state.copyWith(
                  isVerified: true, failedAttempts: 0, clearError: true);
              return true;
            }
          }
        }
      }

      await _handleFailedAttempt();
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error verifying PIN: $e');
      return false;
    }
  }

  // ── Local only verify ───────────────────────────────────────
  Future<bool> verifyPinLocally(String pin) async {
    if (_checkAndUpdateLockout()) return false;
    return verifyPinWithCloudFallback(pin);
  }

  // ── Reset PIN ───────────────────────────────────────────────
  Future<bool> resetPinForAuthenticatedUser(
      String newPin, String confirmPin) async {
    try {
      final auth = _ref.read(firebaseAuthProvider);
      if (auth.currentUser == null || auth.currentUser!.isAnonymous) {
        state = state.copyWith(errorMessage: 'Must be logged in to reset PIN');
        return false;
      }
      if (newPin.isEmpty || newPin.length < 4) {
        state = state.copyWith(errorMessage: 'PIN must be at least 4 digits');
        return false;
      }
      if (newPin != confirmPin) {
        state = state.copyWith(errorMessage: 'PINs do not match');
        return false;
      }

      final localSuccess = await BiometricService.setBiometricPin(newPin);
      if (!localSuccess) {
        state = state.copyWith(errorMessage: 'Failed to save PIN');
        return false;
      }

      await _syncPinToCloud(newPin, auth.currentUser!.uid);
      await _clearLockout();
      state = state.copyWith(isPinSet: true, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error resetting PIN: $e');
      return false;
    }
  }

  void resetVerification() =>
      state = state.copyWith(isVerified: false, failedAttempts: 0);

  void clearError() => state = state.copyWith(clearError: true);
}
