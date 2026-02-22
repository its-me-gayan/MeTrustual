import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UUIDPersistenceService {
  static const _userIdKey = 'user_id';
  static const _userIdSecureKey = 'user_id_secure';
  static const _uuidBackupKey = 'uuid_backup_timestamp';
  static const _secureStorage = FlutterSecureStorage();

  /// Save UUID to both local storage and secure storage
  static Future<void> saveUUID(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Store in SharedPreferences for quick access
      await prefs.setString(_userIdKey, uid);

      // Also store in secure storage for extra protection
      await _secureStorage.write(key: _userIdSecureKey, value: uid);

      // Mark backup time
      await prefs.setInt(_uuidBackupKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('UUID save error: $e');
    }
  }

  /// Retrieve UUID from local storage
  static Future<String?> getUUID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var uuid = prefs.getString(_userIdKey);

      // Fallback to secure storage if not found
      if (uuid == null) {
        uuid = await _secureStorage.read(key: _userIdSecureKey);
      }

      return uuid;
    } catch (e) {
      print('UUID retrieval error: $e');
      return null;
    }
  }

  /// Backup UUID to Firestore for recovery
  static Future<void> backupUUIDToCloud(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).set({
        'uuidBackupDate': FieldValue.serverTimestamp(),
        'deviceBackupTime': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('UUID cloud backup error: $e');
    }
  }

  /// Check if UUID exists locally
  static Future<bool> hasUUID() async {
    try {
      final uuid = await getUUID();
      return uuid != null && uuid.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Verify UUID consistency across storage
  static Future<bool> verifyUUIDConsistency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uuid1 = prefs.getString(_userIdKey);
      final uuid2 = await _secureStorage.read(key: _userIdSecureKey);

      // If one exists and other doesn't, sync them
      if (uuid1 != null && uuid2 == null) {
        await _secureStorage.write(key: _userIdSecureKey, value: uuid1);
        return true;
      } else if (uuid2 != null && uuid1 == null) {
        await prefs.setString(_userIdKey, uuid2);
        return true;
      }

      return uuid1 == uuid2;
    } catch (e) {
      return false;
    }
  }

  /// Clear UUID (on logout/account reset)
  static Future<void> clearUUID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_uuidBackupKey);
      await _secureStorage.delete(key: _userIdSecureKey);
    } catch (e) {
      print('UUID clear error: $e');
    }
  }

  /// Get last UUID backup time
  static Future<DateTime?> getLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_uuidBackupKey);

      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
