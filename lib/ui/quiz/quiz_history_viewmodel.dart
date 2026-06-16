import 'package:flutter/foundation.dart';
import '../../domain/model/quiz_question.dart';
import '../../domain/model/quiz_attempt.dart';
import '../../domain/repository/quiz_repository.dart';

/// Manages the list of past quiz attempts (Read), editing notes (Update),
/// deleting attempts (Delete), and seeding the question bank.
class QuizHistoryViewModel extends ChangeNotifier {
  final QuizRepository _repository;
  final String userId;

  QuizHistoryViewModel(
      {required QuizRepository repository, required this.userId})
      : _repository = repository;

  late final Stream<List<QuizAttempt>> attemptsStream =
      _repository.watchAttempts(userId);

  Future<void> updateNote(String attemptId, String note) =>
      _repository.updateAttemptNote(attemptId: attemptId, note: note);

  Future<void> deleteAttempt(String attemptId) =>
      _repository.deleteAttempt(attemptId);

  Future<void> seedQuestions() =>
      _repository.seedSampleQuestions(kSampleQuizQuestions);
}
