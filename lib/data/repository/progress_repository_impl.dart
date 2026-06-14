import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repository/progress_repository.dart';
import '../../domain/model/progress_record.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final _db = FirebaseFirestore.instance;
  static const _col = 'progress';
  static const _sessions = 'debateSessions';

  @override
  Stream<ProgressRecord?> watchProgress(String userId) {
    return _db.collection(_col).doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ProgressRecord.fromDoc(doc);
    });
  }

  @override
  Future<void> upsertAfterSession({
    required String userId,
    required int score,
  }) async {
    final ref = _db.collection(_col).doc(userId);
    final streak = await _computeStreak(userId);
    final doc = await ref.get();

    if (!doc.exists) {
      final newScores = score > 0 ? [score] : <int>[];
      final badges = _checkBadges(
        scores: newScores,
        streak: streak,
        totalSessions: 1,
        existing: [],
      );
      await ref.set(ProgressRecord(
        progressId: userId,
        userId: userId,
        scores: newScores,
        streak: streak,
        badges: badges,
        totalSessions: 1,
        weeklyGoal: 5,
        updatedAt: DateTime.now(),
      ).toMap());
    } else {
      final current = ProgressRecord.fromDoc(doc);
      final newScores = [...current.scores, if (score > 0) score];
      final newTotal = current.totalSessions + 1;
      final newBadges = _checkBadges(
        scores: newScores,
        streak: streak,
        totalSessions: newTotal,
        existing: current.badges,
      );
      await ref.update({
        'scores': newScores,
        'streak': streak,
        'badges': newBadges,
        'totalSessions': newTotal,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  @override
  Future<void> updateWeeklyGoal({
    required String userId,
    required int goal,
  }) async {
    final ref = _db.collection(_col).doc(userId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.update({'weeklyGoal': goal});
    } else {
      await ref.set(ProgressRecord(
        progressId: userId,
        userId: userId,
        scores: [],
        streak: 0,
        badges: [],
        totalSessions: 0,
        weeklyGoal: goal,
        updatedAt: DateTime.now(),
      ).toMap());
    }
  }

  @override
  Future<void> removeScore({required String userId, required int score}) async {
    await _db.collection(_col).doc(userId).update({
      'scores': FieldValue.arrayRemove([score]),
      'totalSessions': FieldValue.increment(-1),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<int> _computeStreak(String userId) async {
    final snap = await _db
        .collection(_sessions)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    if (snap.docs.isEmpty) return 0;

    // Normalize each session to its calendar day
    final days = snap.docs
        .map((d) => (d.data()['createdAt'] as Timestamp).toDate())
        .map((dt) => DateTime(dt.year, dt.month, dt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    if (days.isEmpty) return 0;

    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Streak only valid if there is activity today or yesterday
    if (days.first.isBefore(today.subtract(const Duration(days: 1)))) return 0;

    int streak = 0;
    DateTime expected = days.first;
    for (final day in days) {
      if (day == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  List<String> _checkBadges({
    required List<int> scores,
    required int streak,
    required int totalSessions,
    required List<String> existing,
  }) {
    final badges = Set<String>.from(existing);
    if (totalSessions >= 1) badges.add('first_debate');
    if (scores.any((s) => s >= 8)) badges.add('high_scorer');
    if (scores.any((s) => s == 10)) badges.add('perfect');
    if (streak >= 3) badges.add('on_a_roll');
    if (totalSessions >= 10) badges.add('veteran');
    if (streak >= 7) badges.add('week_warrior');
    return badges.toList();
  }
}
