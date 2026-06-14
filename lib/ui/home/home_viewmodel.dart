import 'package:flutter/foundation.dart';
import '../../domain/model/debate_session.dart';
import '../../domain/repository/debate_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final DebateRepository _debateRepository;

  HomeViewModel({required DebateRepository debateRepository})
      : _debateRepository = debateRepository;

  Stream<List<DebateSession>>? _sessionsStream;

  Stream<List<DebateSession>> getRecentSessions(String userId) {
    _sessionsStream ??= _debateRepository.getUserSessions(userId);
    return _sessionsStream!;
  }

  Future<void> deleteSession(String sessionId) =>
      _debateRepository.deleteSession(sessionId);
}
