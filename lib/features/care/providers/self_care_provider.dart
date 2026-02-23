import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/mode_provider.dart';

// ── Helper: maps app mode key → Firestore collection name ───────
String _collectionFor(String mode) {
  if (mode == 'preg') return 'pregnancy';
  if (mode == 'ovul') return 'fertility';
  return 'period';
}

// ── Phase data provider ──────────────────────────────────────────
final phaseDataProvider =
    StreamProvider.family<Map<String, String>, String>((ref, phase) {
  final firestore = ref.watch(firestoreProvider);
  final currentMode = ref.watch(modeProvider);
  final collectionName = _collectionFor(currentMode);

  return firestore
      .collection('config')
      .doc('self_care')
      .collection(collectionName)
      .doc(phase)
      .snapshots()
      .asyncMap((DocumentSnapshot<Map<String, dynamic>> snapshot) async {
    if (!snapshot.exists && collectionName != currentMode) {
      final altDoc = await firestore
          .collection('config')
          .doc('self_care')
          .collection(currentMode)
          .doc(phase)
          .get();
      if (altDoc.exists) {
        final d = altDoc.data() ?? {};
        return {
          'badge': d['badge'] as String? ?? '',
          'hero_e': d['hero_e'] as String? ?? '',
          'hero_t': d['hero_t'] as String? ?? '',
          'hero_d': d['hero_d'] as String? ?? '',
        };
      }
    }
    if (!snapshot.exists) return <String, String>{};
    final d = snapshot.data() ?? {};
    return {
      'badge': d['badge'] as String? ?? '',
      'hero_e': d['hero_e'] as String? ?? '',
      'hero_t': d['hero_t'] as String? ?? '',
      'hero_d': d['hero_d'] as String? ?? '',
    };
  });
});

// ── Ritual list provider ─────────────────────────────────────────
final ritualListProvider =
    StreamProvider.family<List<Map<String, String>>, String>((ref, phase) {
  final firestore = ref.watch(firestoreProvider);
  final currentMode = ref.watch(modeProvider);
  final collectionName = _collectionFor(currentMode);

  return firestore
      .collection('config')
      .doc('self_care')
      .collection(collectionName)
      .doc(phase)
      .collection('rituals')
      .orderBy('order', descending: false)
      .snapshots()
      .asyncMap((QuerySnapshot<Map<String, dynamic>> snapshot) async {
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

    return docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final d = doc.data();
      return <String, String>{
        'e': d['emoji'] as String? ?? '',
        't': d['title'] as String? ?? '',
        's': d['subtitle'] as String? ?? '',
        'dur': d['duration'] as String? ?? '0 min',
      };
    }).toList();
  });
});

// ── All phases for current mode provider ────────────────────────
final phasesForModeProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final currentMode = ref.watch(modeProvider);
  final collectionName = _collectionFor(currentMode);

  return firestore
      .collection('config')
      .doc('self_care')
      .collection(collectionName)
      .orderBy('order', descending: false)
      .snapshots()
      .asyncMap((QuerySnapshot<Map<String, dynamic>> snapshot) async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;

    if (docs.isEmpty && collectionName != currentMode) {
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

    return docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final d = doc.data();
      return <String, dynamic>{
        'key': doc.id,
        'emoji': d['emoji'] as String? ?? '',
        'label': d['label'] as String? ?? '',
      };
    }).toList();
  });
});
