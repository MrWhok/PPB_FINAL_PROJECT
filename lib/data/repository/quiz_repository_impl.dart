import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repository/quiz_repository.dart';
import '../../domain/model/quiz_question.dart';
import '../../domain/model/quiz_attempt.dart';
import '../remote/quiz_remote_datasource.dart';

class QuizRepositoryImpl implements QuizRepository {
  final _firestore = FirebaseFirestore.instance;
  final QuizRemoteDatasource _remote = QuizRemoteDatasource();
  static const _questions = 'quizQuestions';
  static const _attempts = 'quizAttempts';

  // ---------------- Questions: AI ----------------
  @override
  Future<List<QuizQuestion>> generateQuestions({
    required String category,
    int count = 5,
  }) {
    return _remote.generate(category: category, count: count);
  }

  // ---------------- Questions: seed bank (opsional) ----------------
  @override
  Stream<List<QuizQuestion>> getQuestions() {
    return _firestore.collection(_questions).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => QuizQuestion.fromMap(doc.data())).toList());
  }

  @override
  Future<void> seedSampleQuestions(List<QuizQuestion> questions) async {
    final batch = _firestore.batch();
    for (final q in questions) {
      final ref = _firestore.collection(_questions).doc(q.questionId);
      batch.set(ref, q.toMap());
    }
    await batch.commit();
  }

  // ---------------- Attempts (CRUD) ----------------
  @override
  Future<void> addAttempt(QuizAttempt attempt) async {
    final ref = attempt.attemptId.isEmpty
        ? _firestore.collection(_attempts).doc()
        : _firestore.collection(_attempts).doc(attempt.attemptId);

    final toSave = QuizAttempt(
      attemptId: ref.id,
      userId: attempt.userId,
      category: attempt.category,
      score: attempt.score,
      total: attempt.total,
      note: attempt.note,
      createdAt: attempt.createdAt,
    );
    await ref.set(toSave.toMap());
  }

  @override
  Stream<List<QuizAttempt>> watchAttempts(String userId) {
    // Hanya filter userId (tanpa orderBy) supaya TIDAK butuh composite index.
    // Pengurutan terbaru-dulu dilakukan di sisi klien.
    return _firestore
        .collection(_attempts)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list =
      snapshot.docs.map((doc) => QuizAttempt.fromDoc(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> updateAttemptNote({
    required String attemptId,
    required String note,
  }) async {
    await _firestore
        .collection(_attempts)
        .doc(attemptId)
        .update({'note': note});
  }

  @override
  Future<void> deleteAttempt(String attemptId) async {
    await _firestore.collection(_attempts).doc(attemptId).delete();
  }
}