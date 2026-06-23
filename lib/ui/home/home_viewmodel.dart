import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/model/debate_session.dart';
import '../../domain/repository/debate_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final DebateRepository _debateRepository;
  Stream<List<DebateSession>>? _sessionsStream;
  late final StreamSubscription<User?> _authSub;

  HomeViewModel({required DebateRepository debateRepository})
      : _debateRepository = debateRepository {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      _sessionsStream = null;
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  Stream<List<DebateSession>> getRecentSessions(String userId) {
    _sessionsStream ??= _debateRepository.getUserSessions(userId);
    return _sessionsStream!;
  }

  Future<void> deleteSession(String sessionId) =>
      _debateRepository.deleteSession(sessionId);
}
