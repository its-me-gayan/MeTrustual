import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _biometricSetKey = 'biometric_set_up';
  static const _pinKey = 'user_pin';

  static Future<bool> isBiometricAvailable() async {
    final localAuth = LocalAuthentication();
    try {
      return await localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setBiometricPin(String pin) async {
    try {
      await _secureStorage.write(key: _pinKey, value: pin);
      // Write flag to BOTH places so they stay in sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricSetKey, true);
      await _secureStorage.write(key: _biometricSetKey, value: 'true');
      return true;
    } catch (e) {
      print('❌ setBiometricPin error: $e');
      return false;
    }
  }

  static Future<bool> isBiometricSetUp() async {
    try {
      // Check BOTH — if either says true, trust it
      final prefs = await SharedPreferences.getInstance();
      final prefFlag = prefs.getBool(_biometricSetKey) ?? false;

      final secureFlag = await _secureStorage.read(key: _biometricSetKey);
      final secureFlagBool = secureFlag == 'true';

      // Also directly check if PIN exists in secure storage
      final pin = await _secureStorage.read(key: _pinKey);
      final pinExists = pin != null && pin.isNotEmpty;

      // If PIN exists but flag was lost — heal the flag
      if (pinExists && !prefFlag) {
        await prefs.setBool(_biometricSetKey, true);
      }

      return prefFlag || secureFlagBool || pinExists;
    } catch (e) {
      print('❌ isBiometricSetUp error: $e');
      return false;
    }
  }

  static Future<bool> verifyWithBiometric() async {
    final localAuth = LocalAuthentication();
    try {
      return await localAuth.authenticate(
        localizedReason: 'Authenticate to access Soluna',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  static Future<bool> verifyWithPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: _pinKey);
      return storedPin == pin;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getPin() async {
    try {
      return await _secureStorage.read(key: _pinKey);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> resetBiometric() async {
    try {
      await _secureStorage.delete(key: _pinKey);
      await _secureStorage.delete(key: _biometricSetKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricSetKey, false);
      return true;
    } catch (e) {
      return false;
    }
  }
}
