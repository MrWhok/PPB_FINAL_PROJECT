import 'package:cloud_firestore/cloud_firestore.dart';

class DebateSession {
  final String sessionId;
  final String userId;
  final String topicId;
  final String topicTitle;
  final String stance;
  final int score;
  final String feedback;
  final DateTime createdAt;

  const DebateSession({
    required this.sessionId,
    required this.userId,
    required this.topicId,
    required this.topicTitle,
    required this.stance,
    this.score = 0,
    this.feedback = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'userId': userId,
        'topicId': topicId,
        'topicTitle': topicTitle,
        'stance': stance,
        'score': score,
        'feedback': feedback,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory DebateSession.fromMap(Map<String, dynamic> map) => DebateSession(
        sessionId: map['sessionId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        topicId: map['topicId'] as String? ?? '',
        topicTitle: map['topicTitle'] as String? ?? 'Unknown Topic',
        stance: map['stance'] as String? ?? 'pro',
        score: map['score'] as int? ?? 0,
        feedback: map['feedback'] as String? ?? '',
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory DebateSession.fromDoc(DocumentSnapshot doc) =>
      DebateSession.fromMap(doc.data() as Map<String, dynamic>);
}
