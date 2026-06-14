import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressRecord {
  final String progressId;
  final String userId;
  final List<int> scores;
  final int streak;
  final List<String> badges;
  final int totalSessions;
  final int weeklyGoal;
  final DateTime updatedAt;

  const ProgressRecord({
    required this.progressId,
    required this.userId,
    required this.scores,
    required this.streak,
    required this.badges,
    required this.totalSessions,
    required this.weeklyGoal,
    required this.updatedAt,
  });

  double get avgScore =>
      scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length;
  int get bestScore =>
      scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b);

  Map<String, dynamic> toMap() => {
        'progressId': progressId,
        'userId': userId,
        'scores': scores,
        'streak': streak,
        'badges': badges,
        'totalSessions': totalSessions,
        'weeklyGoal': weeklyGoal,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory ProgressRecord.fromMap(Map<String, dynamic> map) => ProgressRecord(
        progressId: map['progressId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        scores: List<int>.from(map['scores'] as List? ?? []),
        streak: map['streak'] as int? ?? 0,
        badges: List<String>.from(map['badges'] as List? ?? []),
        totalSessions: map['totalSessions'] as int? ?? 0,
        weeklyGoal: map['weeklyGoal'] as int? ?? 5,
        updatedAt:
            (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory ProgressRecord.fromDoc(DocumentSnapshot doc) =>
      ProgressRecord.fromMap(doc.data() as Map<String, dynamic>);
}
