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

// ── Helper: sort docs by 'order' field client-side ──────────────
// Firestore's orderBy() silently drops docs missing the field.
List<T> _sortByOrder<T extends DocumentSnapshot>(List<T> docs) {
  final sorted = List<T>.from(docs);
  sorted.sort((a, b) {
    final aOrder = (a.data() as Map<String, dynamic>?)?['order'];
    final bOrder = (b.data() as Map<String, dynamic>?)?['order'];
    if (aOrder == null && bOrder == null) return 0;
    if (aOrder == null) return 1;
    if (bOrder == null) return -1;
    return (aOrder as num).compareTo(bOrder as num);
  });
  return sorted;
}

// ── Field-name helper ────────────────────────────────────────────
// The HTML prototype uses short keys (e, t, s, dur, l).
// Firestore may have been populated with those short names OR with
// long names (emoji, title, subtitle, duration, label).
// Tries each key in order, returns the first non-empty value.
String _str(Map<String, dynamic> d, List<String> keys, [String fallback = '']) {
  for (final k in keys) {
    final v = d[k];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return fallback;
}

// ── Phase data provider ──────────────────────────────────────────
final phaseDataProvider =
    StreamProvider.family<Map<String, String>, String>((ref, phase) {
  final firestore = ref.watch(firestoreProvider);
  final currentMode = ref.watch(modeProvider);
  final collectionName = _collectionFor(currentMode);

  Map<String, String> _parseDoc(Map<String, dynamic> d) {
    // hero data may be nested under 'hero' map (matches HTML) or flat hero_* fields
    final heroMap = d['hero'] as Map<String, dynamic>?;
    return {
      'badge': _str(d, ['badge']),
      'hero_e': heroMap != null
          ? _str(heroMap, ['e', 'emoji'])
          : _str(d, ['hero_e', 'heroEmoji']),
      'hero_t': heroMap != null
          ? _str(heroMap, ['t', 'title'])
          : _str(d, ['hero_t', 'heroTitle']),
      'hero_d': heroMap != null
          ? _str(heroMap, ['d', 'desc', 'description'])
          : _str(d, ['hero_d', 'heroDesc']),
    };
  }

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
      if (altDoc.exists) return _parseDoc(altDoc.data() ?? {});
    }
    if (!snapshot.exists) return <String, String>{};
    return _parseDoc(snapshot.data() ?? {});
  });
});

// ── Ritual list provider ─────────────────────────────────────────
final ritualListProvider =
    StreamProvider.family<List<Map<String, String>>, String>((ref, phase) {
  final firestore = ref.watch(firestoreProvider);
  final currentMode = ref.watch(modeProvider);
  final collectionName = _collectionFor(currentMode);

  List<Map<String, String>> _parseDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return _sortByOrder(docs).map((doc) {
      final d = doc.data();
      // Short keys first (HTML prototype format), long keys as fallback
      return <String, String>{
        'e': _str(d, ['e', 'emoji']),
        't': _str(d, ['t', 'title']),
        's': _str(d, ['s', 'subtitle']),
        'dur': _str(d, ['dur', 'duration'], '0 min'),
      };
    }).toList();
  }

  return firestore
      .collection('config')
      .doc('self_care')
      .collection(collectionName)
      .doc(phase)
      .collection('rituals')
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
          .get();
      if (altSnapshot.docs.isNotEmpty) docs = altSnapshot.docs;
    }

    return _parseDocs(docs);
  });
});

// ── All phases for current mode provider ────────────────────────
final phasesForModeProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final currentMode = ref.watch(modeProvider);
  final collectionName = _collectionFor(currentMode);

  List<Map<String, dynamic>> _parseDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return _sortByOrder(docs).map((doc) {
      final d = doc.data();
      // HTML prototype nests emoji+label under 'tab': {e:'🩸', l:'Menstrual'}
      // Firestore may store them flat at root or still nested under 'tab'
      final tabMap = d['tab'] as Map<String, dynamic>?;
      final emoji = tabMap != null
          ? _str(tabMap, ['e', 'emoji'])
          : _str(d, ['e', 'emoji', 'hero_e']);
      final label = tabMap != null
          ? _str(tabMap, ['l', 'label'])
          : _str(d, ['l', 'label']);
      return <String, dynamic>{
        'key': doc.id,
        'emoji': emoji,
        'label': label,
      };
    }).toList();
  }

  return firestore
      .collection('config')
      .doc('self_care')
      .collection(collectionName)
      .snapshots()
      .asyncMap((QuerySnapshot<Map<String, dynamic>> snapshot) async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;

    if (docs.isEmpty && collectionName != currentMode) {
      final altSnapshot = await firestore
          .collection('config')
          .doc('self_care')
          .collection(currentMode)
          .get();
      if (altSnapshot.docs.isNotEmpty) docs = altSnapshot.docs;
    }

    return _parseDocs(docs);
  });
});

// ── Today's ritual completions provider ─────────────────────────
// Streams users/{uid}/ritual_completions/{YYYY-MM-DD}
// Returns Map<phase, Set<int>> — e.g. {"Early": {0, 2}}
// Used by the main screen ritual tiles to show completion badges.

String _todayDocKey() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

final todayRitualCompletionsProvider =
    StreamProvider<Map<String, Set<int>>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final uid = auth.currentUser?.uid;
  if (uid == null) return Stream.value({});

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(uid)
      .collection('ritual_completions')
      .doc(_todayDocKey())
      .snapshots()
      .map((snap) {
    if (!snap.exists) return <String, Set<int>>{};
    final data = snap.data() ?? {};
    final result = <String, Set<int>>{};
    for (final entry in data.entries) {
      if (entry.value is List) {
        result[entry.key] = (entry.value as List).whereType<int>().toSet();
      }
    }
    return result;
  });
});
