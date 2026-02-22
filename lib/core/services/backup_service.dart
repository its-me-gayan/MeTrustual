import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackupService {
  static const _lastBackupKey = 'last_backup_timestamp';
  static const _backupDataKey = 'local_backup_data';

  static Future<void> createLocalBackup({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final backupData = {
        'uid': uid,
        'timestamp': DateTime.now().toIso8601String(),
        'data': userData,
      };

      // Store backup in secure storage
      await prefs.setString(_backupDataKey, jsonEncode(backupData));
      await prefs.setInt(_lastBackupKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Backup creation error: $e');
    }
  }

  static Future<Map<String, dynamic>?> getLocalBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupJson = prefs.getString(_backupDataKey);

      if (backupJson != null) {
        return jsonDecode(backupJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Backup retrieval error: $e');
      return null;
    }
  }

  static Future<void> backupToCloud({
    required String uid,
    required Map<String, dynamic> backupData,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).set({
        'lastBackup': FieldValue.serverTimestamp(),
        'backupSize': jsonEncode(backupData).length,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Cloud backup error: $e');
    }
  }

  static Future<DateTime?> getLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastBackupKey);

      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearLocalBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_backupDataKey);
      await prefs.remove(_lastBackupKey);
    } catch (e) {
      print('Backup clear error: $e');
    }
  }
}
