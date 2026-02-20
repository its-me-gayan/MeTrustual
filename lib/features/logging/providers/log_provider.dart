import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/daily_log_model.dart';

final logProvider = StateNotifierProvider<LogNotifier, AsyncValue<void>>((ref) {
  return LogNotifier(ref);
});

class LogNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  LogNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> saveLog(DailyLog log) async {
    state = const AsyncValue.loading();
    try {
      final firestore = _ref.read(firestoreProvider);
      final auth = _ref.read(firebaseAuthProvider);
      final uid = auth.currentUser?.uid;

      if (uid == null) throw Exception('User not logged in');

      await firestore
          .collection('users')
          .doc(uid)
          .collection('logs')
          .doc(log.id)
          .set(log.toFirestore());
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Stream<List<DailyLog>> watchLogs() {
    final firestore = _ref.read(firestoreProvider);
    final auth = _ref.read(firebaseAuthProvider);
    final uid = auth.currentUser?.uid;

    if (uid == null) return Stream.value([]);

    return firestore
        .collection('users')
        .doc(uid)
        .collection('logs')
        .orderBy('date', descending: true)
        .limit(90)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DailyLog.fromFirestore(doc)).toList());
  }
}
