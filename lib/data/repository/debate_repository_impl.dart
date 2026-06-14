import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repository/debate_repository.dart';
import '../../domain/model/debate_session.dart';
import '../../domain/model/message.dart';

class DebateRepositoryImpl implements DebateRepository {
  final _firestore = FirebaseFirestore.instance;
  static const _sessions = 'debateSessions';

  @override
  Future<DebateSession> createSession(DebateSession session) async {
    await _firestore.collection(_sessions).doc(session.sessionId).set(session.toMap());
    return session;
  }

  @override
  Stream<List<Message>> getMessages(String sessionId) {
    return _firestore
        .collection(_sessions)
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((s) => s.docs.map(Message.fromDoc).toList());
  }

  @override
  Future<Message> saveMessage({
    required String sessionId,
    required String role,
    required String content,
  }) async {
    final ref = _firestore
        .collection(_sessions)
        .doc(sessionId)
        .collection('messages')
        .doc();

    final message = Message(
      messageId: ref.id,
      sessionId: sessionId,
      role: role,
      content: content,
      timestamp: DateTime.now(),
    );
    await ref.set(message.toMap());
    return message;
  }

  @override
  Future<void> updateSessionScore({
    required String sessionId,
    required int score,
    required String feedback,
  }) async {
    await _firestore
        .collection(_sessions)
        .doc(sessionId)
        .update({'score': score, 'feedback': feedback});
  }

  @override
  Future<void> updateSessionStance({
    required String sessionId,
    required String stance,
  }) async {
    await _firestore
        .collection(_sessions)
        .doc(sessionId)
        .update({'stance': stance});
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final messages = await _firestore
        .collection(_sessions)
        .doc(sessionId)
        .collection('messages')
        .get();
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }
    await _firestore.collection(_sessions).doc(sessionId).delete();
  }

  @override
  Stream<List<DebateSession>> getUserSessions(String userId) {
    return _firestore
        .collection(_sessions)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map(DebateSession.fromDoc).toList());
  }
}
