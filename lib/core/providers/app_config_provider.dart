import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_providers.dart';

class AppConfig {
  final int maxFailedAttempts;
  final int lockoutDurationMinutes;

  const AppConfig({
    this.maxFailedAttempts = 5, // hardcoded fallback
    this.lockoutDurationMinutes = 15, // hardcoded fallback
  });

  factory AppConfig.fromFirestore(Map<String, dynamic> data) {
    return AppConfig(
      maxFailedAttempts: _parseInt(data['maxFailedAttempts']) ?? 5,
      lockoutDurationMinutes: _parseInt(data['lockoutDurationMinutes']) ?? 15,
    );
  }

  /// Safely parses both int and string values from Firestore.
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

// Single fetch, cached for the app session
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  try {
    final firestore = ref.read(firestoreProvider);
    final doc = await firestore.collection('config').doc('appConfig').get();

    if (doc.exists && doc.data() != null) {
      return AppConfig.fromFirestore(doc.data()!);
    }
  } catch (e) {
    // Silently fall back to defaults
  }
  return const AppConfig();
});
