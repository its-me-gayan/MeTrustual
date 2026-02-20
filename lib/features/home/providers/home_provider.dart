import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/prediction_engine.dart';
import '../../../models/cycle_model.dart';

final cycleListProvider = StreamProvider<List<CycleModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final uid = auth.currentUser?.uid;

  if (uid == null) return Stream.value([]);

  return firestore
      .collection('users')
      .doc(uid)
      .collection('cycles')
      .orderBy('startDate', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => CycleModel.fromFirestore(doc)).toList());
});

final homeDataProvider = Provider((ref) {
  final cyclesAsync = ref.watch(cycleListProvider);
  
  return cyclesAsync.when(
    data: (cycles) {
      if (cycles.isEmpty) return null;
      
      final lastCycle = cycles.first;
      final cycleLengths = cycles
          .where((c) => c.length != null)
          .map((c) => c.length!)
          .toList();
          
      final prediction = PredictionEngine.predictNextPeriod(
        lastPeriodStart: lastCycle.startDate,
        cycleLengths: cycleLengths,
      );
      
      final phase = PredictionEngine.getCurrentPhase(
        lastPeriodStart: lastCycle.startDate,
        averageCycleLength: prediction.averageLength,
        averagePeriodLength: 5, // Default
      );
      
      return {
        'lastCycle': lastCycle,
        'prediction': prediction,
        'phase': phase,
      };
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
