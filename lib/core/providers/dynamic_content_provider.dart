import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_providers.dart';

// Symptoms Provider
final symptomsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('config')
      .doc('symptoms')
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return [];
    final data = snapshot.data() as Map<String, dynamic>;
    return (data['items'] as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  });
});

// Education Content Provider
final educationContentProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('education_articles') // ← correct collection name
      .where('isPublished', isEqualTo: true)
      .orderBy('order')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
});

// Insights Tips Provider (Dynamic Tips for the Big Insight box)
final insightTipsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('config')
      .doc('insight_tips')
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return [];
    final data = snapshot.data() as Map<String, dynamic>;
    return (data['tips'] as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  });
});
