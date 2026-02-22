import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/firebase_providers.dart';

/// Provider to load journey steps exclusively from Firestore.
/// This provider will fetch the latest journey data directly from Firebase
/// without any hardcoded fallback values.
final journeyStepsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, mode) async {
  final firestore = ref.read(firestoreProvider);

  try {
    debugPrint('Loading journey steps for mode: $mode from Firestore');
    final doc = await firestore.collection('journeys').doc(mode).get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['steps'] != null) {
        final steps = List<Map<String, dynamic>>.from(data['steps']);
        debugPrint('Successfully loaded ${steps.length} steps for mode: $mode');
        return steps;
      }
    }
    
    debugPrint('No journey document found for mode: $mode');
    throw Exception('Journey document not found for mode: $mode');
  } catch (e) {
    debugPrint('Error loading journey steps for mode $mode: $e');
    rethrow; // Re-throw the error to be handled by the caller
  }
});
