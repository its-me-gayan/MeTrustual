import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String ageGroup; // teen, adult, mature
  final String region; // asia, africa, latam, global
  final String language; // en, ms, es, etc.
  final DateTime createdAt;
  final String lifeStage;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.ageGroup,
    required this.region,
    required this.language,
    required this.createdAt,
    required this.lifeStage,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      ageGroup: data['ageGroup'] ?? 'adult',
      region: data['region'] ?? 'global',
      language: data['language'] ?? 'en',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lifeStage: data['lifeStage'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'ageGroup': ageGroup,
      'region': region,
      'language': language,
      'createdAt': Timestamp.fromDate(createdAt),
      'lifeStage': lifeStage,
    };
  }
}
