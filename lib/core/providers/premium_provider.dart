import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_providers.dart';

final premiumStatusProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(false);
  
  return ref.watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return false;
        final data = snapshot.data();
        return data != null && (data['isPremium'] == true);
      });
});
