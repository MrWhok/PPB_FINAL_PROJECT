import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/model/progress_record.dart';
import '../../domain/repository/progress_repository.dart';

class ProgressViewModel extends ChangeNotifier {
  final ProgressRepository _repository;

  ProgressViewModel({required ProgressRepository repository})
      : _repository = repository;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<ProgressRecord?> get progressStream => _repository.watchProgress(_uid);

  Future<void> updateWeeklyGoal(int goal) =>
      _repository.updateWeeklyGoal(userId: _uid, goal: goal);
}
