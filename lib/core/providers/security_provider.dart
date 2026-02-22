import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/biometric_service.dart';
import 'firebase_providers.dart';

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
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
    int? failedAttempts,
    bool? isLocked,
    DateTime? lockUntil,
  }) {
    return SecurityState(
      isPinSet: isPinSet ?? this.isPinSet,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: errorMessage ?? this.errorMessage,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      isLocked: isLocked ?? this.isLocked,
      lockUntil: lockUntil ?? this.lockUntil,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  final Ref _ref;
  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  SecurityNotifier(this._ref) : super(SecurityState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final isBioAvailable = await BiometricService.isBiometricAvailable();
    final isPinSet = await BiometricService.isBiometricSetUp();
    state = state.copyWith(
      isBiometricAvailable: isBioAvailable,
      isPinSet: isPinSet,
    );
  }

  /// Generate a hash and salt for the PIN
  Map<String, String> _generatePinHash(String pin) {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    return {'hash': hash, 'salt': salt};
  }

  /// Generate a random salt
  String _generateSalt() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Hash the PIN with salt using SHA-256
  String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$pin$salt')).toString();
  }

  /// Set PIN for a new user (local + cloud for authenticated users)
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

      // Save locally using BiometricService
      final success = await BiometricService.setBiometricPin(pin);
      if (!success) {
        state = state.copyWith(errorMessage: 'Failed to save PIN locally');
        return false;
      }

      // If user is authenticated, sync to Firestore
      final auth = _ref.read(firebaseAuthProvider);
      if (auth.currentUser != null && !auth.currentUser!.isAnonymous) {
        await _syncPinToCloud(pin, auth.currentUser!.uid);
      }

      state = state.copyWith(isPinSet: true, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error setting PIN: ${e.toString()}');
      return false;
    }
  }

  /// Sync PIN hash to Firestore for authenticated users
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
      print('Error syncing PIN to cloud: $e');
      // Don't fail the operation if cloud sync fails
    }
  }

  /// Verify PIN locally
  Future<bool> verifyPinLocally(String pin) async {
    try {
      // Check if locked
      if (state.isLocked && state.lockUntil != null) {
        if (DateTime.now().isBefore(state.lockUntil!)) {
          state = state.copyWith(
            errorMessage: 'Too many failed attempts. Try again later.',
          );
          return false;
        } else {
          // Unlock after timeout
          state = state.copyWith(isLocked: false, failedAttempts: 0, lockUntil: null);
        }
      }

      final verified = await BiometricService.verifyWithPin(pin);
      if (verified) {
        state = state.copyWith(
          isVerified: true,
          failedAttempts: 0,
          errorMessage: null,
        );
        return true;
      } else {
        final newFailedAttempts = state.failedAttempts + 1;
        final isNowLocked = newFailedAttempts >= _maxFailedAttempts;

        state = state.copyWith(
          failedAttempts: newFailedAttempts,
          isLocked: isNowLocked,
          lockUntil: isNowLocked ? DateTime.now().add(_lockoutDuration) : null,
          errorMessage: isNowLocked
              ? 'Too many failed attempts. Try again in 15 minutes.'
              : 'Incorrect PIN. Attempts remaining: ${_maxFailedAttempts - newFailedAttempts}',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error verifying PIN: ${e.toString()}');
      return false;
    }
  }

  /// Verify PIN with cloud fallback for authenticated users
  Future<bool> verifyPinWithCloudFallback(String pin) async {
    try {
      // First try local verification
      final localVerified = await BiometricService.verifyWithPin(pin);
      if (localVerified) {
        state = state.copyWith(isVerified: true, failedAttempts: 0);
        return true;
      }

      // If local fails, try cloud verification for authenticated users
      final auth = _ref.read(firebaseAuthProvider);
      if (auth.currentUser != null && !auth.currentUser!.isAnonymous) {
        final firestore = _ref.read(firestoreProvider);
        final uid = auth.currentUser!.uid;
        final doc = await firestore.collection('users').doc(uid).get();

        if (doc.exists) {
          final cloudHash = doc.data()?['pinHash'] as String?;
          final cloudSalt = doc.data()?['pinSalt'] as String?;

          if (cloudHash != null && cloudSalt != null) {
            final enteredHash = _hashPin(pin, cloudSalt);
            if (enteredHash == cloudHash) {
              state = state.copyWith(isVerified: true, failedAttempts: 0);
              return true;
            }
          }
        }
      }

      // Failed verification
      final newFailedAttempts = state.failedAttempts + 1;
      final isNowLocked = newFailedAttempts >= _maxFailedAttempts;

      state = state.copyWith(
        failedAttempts: newFailedAttempts,
        isLocked: isNowLocked,
        lockUntil: isNowLocked ? DateTime.now().add(_lockoutDuration) : null,
        errorMessage: isNowLocked
            ? 'Too many failed attempts. Try again in 15 minutes.'
            : 'Incorrect PIN. Attempts remaining: ${_maxFailedAttempts - newFailedAttempts}',
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error verifying PIN: ${e.toString()}');
      return false;
    }
  }

  /// Reset PIN for authenticated users (via email verification)
  Future<bool> resetPinForAuthenticatedUser(String newPin, String confirmPin) async {
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

      // Save locally
      final localSuccess = await BiometricService.setBiometricPin(newPin);
      if (!localSuccess) {
        state = state.copyWith(errorMessage: 'Failed to save PIN locally');
        return false;
      }

      // Sync to cloud
      await _syncPinToCloud(newPin, auth.currentUser!.uid);

      state = state.copyWith(isPinSet: true, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error resetting PIN: ${e.toString()}');
      return false;
    }
  }

  /// Reset verification state
  void resetVerification() {
    state = state.copyWith(isVerified: false, failedAttempts: 0);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
