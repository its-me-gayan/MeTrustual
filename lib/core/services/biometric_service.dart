import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const _secureStorage = FlutterSecureStorage();
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricSetKey, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> verifyWithBiometric() async {
    final localAuth = LocalAuthentication();
    try {
      return await localAuth.authenticate(
        localizedReason: 'Authenticate to access MeTrustual',
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

  static Future<bool> isBiometricSetUp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricSetKey) ?? false;
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricSetKey, false);
      return true;
    } catch (e) {
      return false;
    }
  }
}
