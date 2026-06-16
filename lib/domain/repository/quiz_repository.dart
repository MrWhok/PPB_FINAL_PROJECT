import '../model/quiz_question.dart';
import '../model/quiz_attempt.dart';

abstract interface class QuizRepository {
  // Questions (seed bank)
  Stream<List<QuizQuestion>> getQuestions();
  Future<void> seedSampleQuestions(List<QuizQuestion> questions);

  // Attempts (user results) — full CRUD
  Future<void> addAttempt(QuizAttempt attempt); // Create
  Stream<List<QuizAttempt>> watchAttempts(String userId); // Read
  Future<void> updateAttemptNote({
    required String attemptId,
    required String note,
  }); // Update
  Future<void> deleteAttempt(String attemptId); // Delete
}
