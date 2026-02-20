import 'package:cloud_firestore/cloud_firestore.dart';

class CycleModel {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final int? length;
  final String? notes;

  CycleModel({
    required this.id,
    required this.startDate,
    this.endDate,
    this.length,
    this.notes,
  });

  factory CycleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CycleModel(
      id: doc.id,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      length: data['length'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'length': length,
      'notes': notes,
    };
  }
}
