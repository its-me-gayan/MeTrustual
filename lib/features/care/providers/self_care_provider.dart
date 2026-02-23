import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/mode_provider.dart';

// Phase data provider - fetches from Firestore
final phaseDataProvider = StreamProvider.family<Map<String, String>, String>((ref, phase) {
  final firestore = ref.watch(firestoreProvider);
  final currentMode = ref.watch(modeProvider);

  return firestore
      .collection('config')
      .doc('self_care')
      .collection(currentMode)
      .doc(phase)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return {};
    return {
      'badge': snapshot.data()?['badge'] as String? ?? '',
      'hero_e': snapshot.data()?['hero_e'] as String? ?? '',
      'hero_t': snapshot.data()?['hero_t'] as String? ?? '',
      'hero_d': snapshot.data()?['hero_d'] as String? ?? '',
    };
  });
});

// Ritual list provider - fetches from Firestore
final ritualListProvider = StreamProvider.family<List<Map<String, String>>, String>((ref, phase) {
  final firestore = ref.watch(firestoreProvider);
  final currentMode = ref.watch(modeProvider);

  return firestore
      .collection('config')
      .doc('self_care')
      .collection(currentMode)
      .doc(phase)
      .collection('rituals')
      .orderBy('order', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return {
        'e': doc.data()['emoji'] as String? ?? '',
        't': doc.data()['title'] as String? ?? '',
        's': doc.data()['subtitle'] as String? ?? '',
        'dur': doc.data()['duration'] as String? ?? '0 min',
      };
    }).toList();
  });
});

// All phases for current mode provider
final phasesForModeProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final currentMode = ref.watch(modeProvider);

  return firestore
      .collection('config')
      .doc('self_care')
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return [];
    final data = snapshot.data();
    if (data == null || !data.containsKey(currentMode)) return [];
    
    final List<dynamic> phases = data[currentMode] as List<dynamic>;
    return phases.map((p) {
      final map = p as Map<String, dynamic>;
      return {
        'key': map['key'] as String? ?? '',
        'emoji': map['emoji'] as String? ?? '',
        'label': map['label'] as String? ?? '',
      };
    }).toList();
  });
});
