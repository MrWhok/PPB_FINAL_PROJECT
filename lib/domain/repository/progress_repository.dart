import '../model/progress_record.dart';

abstract interface class ProgressRepository {
  Stream<ProgressRecord?> watchProgress(String userId);
  Future<void> upsertAfterSession({
    required String userId,
    required int score,
  });
  Future<void> updateWeeklyGoal({required String userId, required int goal});
  Future<void> removeScore({required String userId, required int score});
}
