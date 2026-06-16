import 'package:cloud_firestore/cloud_firestore.dart';

class QuizAttempt {
  final String attemptId;
  final String userId;
  final String category; // which category was quizzed (or 'Mixed')
  final int score; // number correct
  final int total; // number of questions
  final String note; // optional user note (editable)
  final DateTime createdAt;

  const QuizAttempt({
    required this.attemptId,
    required this.userId,
    required this.category,
    required this.score,
    required this.total,
    this.note = '',
    required this.createdAt,
  });

  double get percentage => total == 0 ? 0 : (score / total) * 100;

  QuizAttempt copyWith({String? note}) => QuizAttempt(
        attemptId: attemptId,
        userId: userId,
        category: category,
        score: score,
        total: total,
        note: note ?? this.note,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'attemptId': attemptId,
        'userId': userId,
        'category': category,
        'score': score,
        'total': total,
        'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory QuizAttempt.fromMap(Map<String, dynamic> map) => QuizAttempt(
        attemptId: map['attemptId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        category: map['category'] as String? ?? 'Mixed',
        score: map['score'] as int? ?? 0,
        total: map['total'] as int? ?? 0,
        note: map['note'] as String? ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory QuizAttempt.fromDoc(DocumentSnapshot doc) =>
      QuizAttempt.fromMap(doc.data() as Map<String, dynamic>);
}
