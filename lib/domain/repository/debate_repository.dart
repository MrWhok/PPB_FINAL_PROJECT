import '../model/debate_session.dart';
import '../model/message.dart';

abstract interface class DebateRepository {
  Future<DebateSession> createSession(DebateSession session);
  Stream<List<Message>> getMessages(String sessionId);
  Future<Message> saveMessage({required String sessionId, required String role, required String content});
  Future<void> updateSessionScore({required String sessionId, required int score, required String feedback});
  Future<void> updateSessionStance({required String sessionId, required String stance});
  Future<void> deleteSession(String sessionId);
  Stream<List<DebateSession>> getUserSessions(String userId);
}
