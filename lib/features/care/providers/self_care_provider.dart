import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/mode_provider.dart';

// Phase data provider - fetches from Firestore
final phaseDataProvider = StreamProvider.family<Map<String, String>, String>((ref, phase) {
  final firestore = ref.watch(firestoreProvider);
  final currentMode = ref.watch(modeProvider);
  
  final collectionName = currentMode == 'preg' 
      ? 'pregnancy' 
      : currentMode == 'ovul' 
          ? 'fertility' 
          : 'period';

  return firestore
      .collection('config')
      .doc('self_care')
      .collection(collectionName)
      .doc(phase)
      .snapshots()
      .asyncMap((snapshot) async {
    if (!snapshot.exists && collectionName != currentMode) {
      final altDoc = await firestore
          .collection('config')
          .doc('self_care')
          .collection(currentMode)
          .doc(phase)
          .get();
      if (altDoc.exists) {
        return {
          'badge': altDoc.data()?['badge'] as String? ?? '',
          'hero_e': altDoc.data()?['hero_e'] as String? ?? '',
          'hero_t': altDoc.data()?['hero_t'] as String? ?? '',
          'hero_d': altDoc.data()?['hero_d'] as String? ?? '',
        };
      }
    }
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

  final collectionName = currentMode == 'preg' 
      ? 'pregnancy' 
      : currentMode == 'ovul' 
          ? 'fertility' 
          : 'period';

  return firestore
      .collection('config')
      .doc('self_care')
      .collection(collectionName)
      .doc(phase)
      .collection('rituals')
      .orderBy('order', descending: false)
      .snapshots()
      .asyncMap((snapshot) async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;
    
    if (docs.isEmpty && collectionName != currentMode) {
      final altSnapshot = await firestore
          .collection('config')
          .doc('self_care')
          .collection(currentMode)
          .doc(phase)
          .collection('rituals')
          .orderBy('order', descending: false)
          .get();
      if (altSnapshot.docs.isNotEmpty) {
        docs = altSnapshot.docs;
      }
    }
    
    return docs.map((doc) {
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

  // Map 'preg' to 'pregnancy' and 'ovul' to 'fertility' if needed
  final collectionName = currentMode == 'preg' 
      ? 'pregnancy' 
      : currentMode == 'ovul' 
          ? 'fertility' 
          : 'period';

  return firestore
      .collection('config')
      .doc('self_care')
      .collection(collectionName)
      .orderBy('order', descending: false)
      .snapshots()
      .asyncMap((snapshot) async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;

    if (docs.isEmpty && collectionName != currentMode) {
      // Fallback: try original mode name if collectionName differs
      final altSnapshot = await firestore
          .collection('config')
          .doc('self_care')
          .collection(currentMode)
          .orderBy('order', descending: false)
          .get();
      if (altSnapshot.docs.isNotEmpty) {
        docs = altSnapshot.docs;
      }
    }
    
    return docs.map((doc) {
      return {
        'key': doc.id,
        'emoji': doc.data()['emoji'] as String? ?? '',
        'label': doc.data()['label'] as String? ?? '',
      };
    }).toList();
  });
});
