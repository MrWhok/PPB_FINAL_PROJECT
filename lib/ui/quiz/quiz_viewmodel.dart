import 'package:flutter/foundation.dart';
import '../../domain/model/quiz_question.dart';
import '../../domain/model/quiz_attempt.dart';
import '../../domain/repository/quiz_repository.dart';

/// Drives a single quiz session: generates questions via AI, tracks the
/// user's answers, computes the score, and persists the attempt to Firestore.
class QuizViewModel extends ChangeNotifier {
  final QuizRepository _repository;
  final String userId;

  QuizViewModel({required QuizRepository repository, required this.userId})
      : _repository = repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<QuizQuestion> _questions = [];
  List<QuizQuestion> get questions => _questions;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  /// User's selected option per question (-1 = not answered).
  late List<int> _answers;

  bool _finished = false;
  bool get finished => _finished;

  String _category = 'Mixed';
  String get category => _category;

  QuizQuestion? get currentQuestion =>
      _questions.isEmpty ? null : _questions[_currentIndex];

  int get total => _questions.length;

  int get score {
    var s = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].correctIndex) s++;
    }
    return s;
  }

  int? selectedFor(int index) =>
      (_answers[index] == -1) ? null : _answers[index];

  /// Generates an AI quiz. [category] == 'Mixed' mixes all categories.
  Future<void> loadQuiz({String category = 'Mixed', int limit = 5}) async {
    _isLoading = true;
    _error = null;
    _finished = false;
    _currentIndex = 0;
    _category = category;
    notifyListeners();

    try {
      final generated =
      await _repository.generateQuestions(category: category, count: limit);
      _questions = generated.take(limit).toList();
      _answers = List<int>.filled(_questions.length, -1);

      if (_questions.isEmpty) {
        _error = 'AI tidak menghasilkan soal. Coba lagi.';
      }
    } catch (e) {
      _error = 'Gagal membuat kuis (cek koneksi/API key): $e';
      _questions = [];
      _answers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectAnswer(int optionIndex) {
    if (_finished) return;
    _answers[_currentIndex] = optionIndex;
    notifyListeners();
  }

  void next() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  bool get isLastQuestion => _currentIndex == _questions.length - 1;
  bool get allAnswered => _answers.isNotEmpty && !_answers.contains(-1);

  /// Marks the quiz finished and saves the attempt (Create).
  Future<void> submit() async {
    _finished = true;
    notifyListeners();
    try {
      final attempt = QuizAttempt(
        attemptId: '',
        userId: userId,
        category: _category,
        score: score,
        total: total,
        createdAt: DateTime.now(),
      );
      await _repository.addAttempt(attempt);
    } catch (e) {
      _error = 'Result saved locally but failed to sync: $e';
      notifyListeners();
    }
  }
}