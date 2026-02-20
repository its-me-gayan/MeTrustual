class DailyLog {
  final String id;
  final DateTime date;
  final String flow;
  final String mood;
  final List<String> symptoms;
  final int painLevel;
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
    this.painLevel = 0,
    this.waterGlasses = 0,
    this.sleepHours = 0,
    this.note = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'date': date.toIso8601String(),
      'flow': flow,
      'mood': mood,
      'symptoms': symptoms,
      'painLevel': painLevel,
      'waterGlasses': waterGlasses,
      'sleepHours': sleepHours,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyLog.fromMap(String id, Map<String, dynamic> data) {
    return DailyLog(
      id: id,
      date: DateTime.parse(data['date']),
      flow: data['flow'] ?? 'none',
      mood: data['mood'] ?? 'okay',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      painLevel: data['painLevel'] ?? 0,
      waterGlasses: data['waterGlasses'] ?? 0,
      sleepHours: data['sleepHours'] ?? 0,
      note: data['note'] ?? '',
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
    );
  }
}
