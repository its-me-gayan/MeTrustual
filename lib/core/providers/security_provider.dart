import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:async';
import 'dart:convert';
import '../services/biometric_service.dart';
import 'firebase_providers.dart';
import 'app_config_provider.dart';

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

  // ── True until _initialize() fully completes ────────────────────
  // The PIN screen must wait for this to flip false before trusting
  // isLocked. Without it, the provider returns isLocked=false for the
  // brief async gap on every restart, making lockout bypassable.
  final bool isInitializing;

  SecurityState({
    this.isPinSet = false,
    this.isBiometricAvailable = false,
    this.isVerified = false,
    this.errorMessage,
    this.failedAttempts = 0,
    this.isLocked = false,
    this.lockUntil,
    this.isInitializing = true, // safe default — locks UI until ready
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
    bool? isInitializing,
  }) {
    return SecurityState(
      isPinSet: isPinSet ?? this.isPinSet,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      isLocked: isLocked ?? this.isLocked,
      lockUntil: clearLockUntil ? null : lockUntil ?? this.lockUntil,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  final Ref _ref;

  // ── SharedPreferences keys ──────────────────────────────────────
  static const String _prefFailedAttempts = 'sec_failed_attempts';
  static const String _prefLockUntil = 'sec_lock_until';

  // ── Fallbacks if remote config is unavailable ───────────────────
  static const int _fallbackMaxFailedAttempts = 5;
  static const int _fallbackLockoutDurationMinutes = 15;

  SecurityNotifier(this._ref) : super(SecurityState()) {
    _initialize();
  }

  // ── Expose a future so router/splash can await full init ────────
  // Usage: await ref.read(securityProvider.notifier).initializationComplete;
  late final Future<void> initializationComplete = _initialize();

  // ── Dynamic config getters ──────────────────────────────────────
  int get _maxFailedAttempts {
    return _ref.read(appConfigProvider).valueOrNull?.maxFailedAttempts ??
        _fallbackMaxFailedAttempts;
  }

  Duration get _lockoutDuration {
    final mins =
        _ref.read(appConfigProvider).valueOrNull?.lockoutDurationMinutes ??
            _fallbackLockoutDurationMinutes;
    // Guard: a zero/negative value from Remote Config would create an
    // instantly-expired lockUntil → isLocked=true but lockUntil in the
    // past → the countdown shows 00:00 and lockout is bypassable.
    final safeMins = (mins > 0) ? mins : _fallbackLockoutDurationMinutes;
    return Duration(minutes: safeMins);
  }

  // ── Init — restore lockout state on every app start ─────────────
  Future<void> _initialize() async {
    await _ref
        .read(appConfigProvider.future)
        .catchError((_) => const AppConfig());

    final isBioAvailable = await BiometricService.isBiometricAvailable();
    final isPinSet = await BiometricService.isBiometricSetUp();

    // ── Step 1: SharedPreferences (fast, works offline) ────────────
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
        errorMessage = _remainingMessage(lockUntil);
      } else {
        // Expired — clear both stores
        await _clearLockout();
        lockUntil = null;
      }
    }

    // ── Step 2: Firestore (catches reinstall / cleared app data) ───
    // Reads from the `security` MAP FIELD on the root user document,
    // which matches the existing Firestore structure:
    //   users/{uid}.security.failedAttempts
    //   users/{uid}.security.lockUntil
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
                isLocked = true;
                lockUntil = lockDate;
                errorMessage = _remainingMessage(lockDate);

                // Mirror to local prefs for next offline launch
                await prefs.setInt(_prefFailedAttempts, cloudAttempts);
                await prefs.setInt(
                    _prefLockUntil, lockDate.millisecondsSinceEpoch);
              }
            }
          }
        }
      } catch (_) {
        // Network failure — local prefs remain the source of truth
      }
    }

    // ── Flip isInitializing → false atomically with real state ──────
    // Nothing that reads isLocked is trustworthy before this point.
    state = state.copyWith(
      isBiometricAvailable: isBioAvailable,
      isPinSet: isPinSet,
      failedAttempts: isLocked ? savedAttempts : 0,
      isLocked: isLocked,
      lockUntil: lockUntil,
      errorMessage: errorMessage,
      isInitializing: false, // ← unlocks the UI
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────
  String _remainingMessage(DateTime lockUntil) {
    final remaining = lockUntil.difference(DateTime.now());
    final mins = remaining.inMinutes;
    final secs = remaining.inSeconds % 60;
    return 'Try again in ${mins > 0 ? '$mins min' : '${secs}s'}.';
  }

  // ── Persist lockout ─────────────────────────────────────────────
  // Writes to SharedPreferences AND to users/{uid}.security (map field)
  // — the exact same structure visible in your Firestore console.
  Future<void> _persistLockout(int attempts, DateTime? lockUntil) async {
    // Local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefFailedAttempts, attempts);
    if (lockUntil != null) {
      await prefs.setInt(_prefLockUntil, lockUntil.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_prefLockUntil);
    }

    // Cloud — map field on root user doc (matches existing structure)
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
    } catch (_) {
      // Local is the fallback
    }
  }

  // ── Clear lockout ────────────────────────────────────────────────
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
    } catch (_) {}
  }

  // ── Check + update lockout ───────────────────────────────────────
  bool _checkAndUpdateLockout() {
    if (state.isLocked && state.lockUntil != null) {
      if (DateTime.now().isBefore(state.lockUntil!)) {
        state = state.copyWith(
          errorMessage:
              'Too many failed attempts. ${_remainingMessage(state.lockUntil!)}',
        );
        return true;
      } else {
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

  // ── Handle failed attempt ────────────────────────────────────────
  Future<void> _handleFailedAttempt() async {
    final newAttempts = state.failedAttempts + 1;
    final maxAttempts = _maxFailedAttempts;
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

  // ── PIN hashing ──────────────────────────────────────────────────
  Map<String, String> _generatePinHash(String pin) {
    final salt = _generateSalt();
    return {'hash': _hashPin(pin, salt), 'salt': salt};
  }

  String _generateSalt() => DateTime.now().millisecondsSinceEpoch.toString();

  String _hashPin(String pin, String salt) =>
      sha256.convert(utf8.encode('$pin$salt')).toString();

  // ── Set PIN ──────────────────────────────────────────────────────
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

  // Writes pinHash + pinSalt to the root user doc (matches original structure)
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

  // ── Verify PIN ───────────────────────────────────────────────────
  Future<bool> verifyPinWithCloudFallback(String pin) async {
    try {
      if (_checkAndUpdateLockout()) return false;

      // Local first
      final localVerified = await BiometricService.verifyWithPin(pin);
      if (localVerified) {
        await _clearLockout();
        state = state.copyWith(
            isVerified: true, failedAttempts: 0, clearError: true);
        return true;
      }

      // Cloud fallback — reads pinHash/pinSalt from root user doc
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
          if (cloudHash != null &&
              cloudSalt != null &&
              _hashPin(pin, cloudSalt) == cloudHash) {
            await _clearLockout();
            state = state.copyWith(
                isVerified: true, failedAttempts: 0, clearError: true);
            return true;
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

  Future<bool> verifyPinLocally(String pin) async {
    if (_checkAndUpdateLockout()) return false;
    return verifyPinWithCloudFallback(pin);
  }

  // ── Reset PIN ────────────────────────────────────────────────────
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

  // ── Called every second by the PIN screen timer ────────────────
  // If the lockout window has passed, clears state so the UI
  // re-enables immediately without requiring an app restart.
  void checkLockoutExpiry() {
    if (!state.isLocked || state.lockUntil == null) return;
    if (DateTime.now().isAfter(state.lockUntil!)) {
      _clearLockout();
      state = state.copyWith(
        isLocked: false,
        failedAttempts: 0,
        clearLockUntil: true,
        clearError: true,
      );
    }
  }

  void resetVerification() =>
      state = state.copyWith(isVerified: false, failedAttempts: 0);

  void clearError() => state = state.copyWith(clearError: true);
}
