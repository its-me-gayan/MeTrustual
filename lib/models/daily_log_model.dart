import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLog {
  final String id; // YYYY-MM-DD
  final DateTime date;
  final String flow; // heavy/medium/light/spotting/none
  final String mood; // low/okay/good/great/tense
  final List<String> symptoms;
  final int painLevel; // 0-10
  final int waterGlasses;
  final int sleepHours;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyLog({
    required this.id,
    required this.date,
    required this.flow,
    required this.mood,
    required this.symptoms,
    required this.painLevel,
    required this.waterGlasses,
    required this.sleepHours,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyLog(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      flow: data['flow'] ?? 'none',
      mood: data['mood'] ?? 'okay',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      painLevel: data['painLevel'] ?? 0,
      waterGlasses: data['waterGlasses'] ?? 0,
      sleepHours: data['sleepHours'] ?? 0,
      note: data['note'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'flow': flow,
      'mood': mood,
      'symptoms': symptoms,
      'painLevel': painLevel,
      'waterGlasses': waterGlasses,
      'sleepHours': sleepHours,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
