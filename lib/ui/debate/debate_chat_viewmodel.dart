import 'package:flutter/foundation.dart';
import '../../domain/model/debate_session.dart';
import '../../domain/model/message.dart';
import '../../domain/repository/debate_repository.dart';
import '../../data/remote/ai_remote_datasource.dart';

class DebateChatViewModel extends ChangeNotifier {
  final DebateRepository _debateRepository;
  final AIRemoteDatasource _aiDatasource;
  final DebateSession session;

  DebateChatViewModel({
    required this.session,
    required DebateRepository debateRepository,
    required AIRemoteDatasource aiDatasource,
  })  : _debateRepository = debateRepository,
        _aiDatasource = aiDatasource,
        _currentStance = session.stance;

  bool _isAiThinking = false;
  bool _sessionEnded = false;
  late String _currentStance;

  bool get isAiThinking => _isAiThinking;
  bool get sessionEnded => _sessionEnded;
  String get currentStance => _currentStance;

  late final Stream<List<Message>> _messagesStream =
      _debateRepository.getMessages(session.sessionId);
  Stream<List<Message>> get messagesStream => _messagesStream;

  Future<Message> sendMessage({
    required String text,
    required List<Message> previousMessages,
    required String language,
  }) async {
    _isAiThinking = true;
    notifyListeners();

    await _debateRepository.saveMessage(
      sessionId: session.sessionId,
      role: 'user',
      content: text,
    );

    try {
      final aiReply = await _aiDatasource.generateCounterArgument(
        userArgument: text,
        topic: session.topicTitle,
        stance: _currentStance,
        language: language,
        previousMessages: previousMessages,
      );
      final aiMessage = await _debateRepository.saveMessage(
        sessionId: session.sessionId,
        role: 'ai',
        content: aiReply,
      );
      return aiMessage;
    } catch (_) {
      return _debateRepository.saveMessage(
        sessionId: session.sessionId,
        role: 'ai',
        content:
            'Could not get a response. Make sure your Groq API key is set in lib/config/secrets.dart.',
      );
    } finally {
      _isAiThinking = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> endSession({
    required List<Message> messages,
    required String language,
  }) async {
    final result = await _aiDatasource.scoreDebate(
      topic: session.topicTitle,
      stance: _currentStance,
      messages: messages,
      language: language,
    );

    final score = result['score'] as int;
    final feedback = result['feedback'] as String;

    await _debateRepository.updateSessionScore(
      sessionId: session.sessionId,
      score: score,
      feedback: feedback,
    );

    _sessionEnded = true;
    notifyListeners();
    return result;
  }

  Future<String?> transcribeAudio({
    required String filePath,
    required String language,
  }) async {
    return _aiDatasource.transcribeAudio(filePath: filePath, language: language);
  }

  Future<void> editStance(String newStance) async {
    if (newStance == _currentStance) return;
    await _debateRepository.updateSessionStance(
      sessionId: session.sessionId,
      stance: newStance,
    );
    _currentStance = newStance;
    notifyListeners();
  }
}
