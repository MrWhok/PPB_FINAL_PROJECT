import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/model/debate_session.dart';
import '../../domain/model/topic.dart';
import '../../domain/repository/debate_repository.dart';
import '../../domain/repository/topic_repository.dart';

class StartDebateViewModel extends ChangeNotifier {
  final DebateRepository _debateRepository;
  final TopicRepository _topicRepository;

  StartDebateViewModel({
    required DebateRepository debateRepository,
    required TopicRepository topicRepository,
  })  : _debateRepository = debateRepository,
        _topicRepository = topicRepository;

  Topic? _selectedTopic;
  String? _selectedStance;
  String _selectedCategory = 'All';
  bool _isLoading = false;

  Topic? get selectedTopic => _selectedTopic;
  String? get selectedStance => _selectedStance;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get canStart => _selectedTopic != null && _selectedStance != null;

  late final Stream<List<Topic>> _topicsStream = _topicRepository.getTopics();
  Stream<List<Topic>> get topicsStream => _topicsStream;

  void selectTopic(Topic? topic) {
    _selectedTopic = topic;
    if (topic == null) _selectedStance = null;
    notifyListeners();
  }

  void selectStance(String? stance) {
    _selectedStance = stance;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<DebateSession?> startDebate() async {
    if (!canStart) return null;
    _isLoading = true;
    notifyListeners();
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final ref = FirebaseFirestore.instance.collection('debateSessions').doc();
      final session = DebateSession(
        sessionId: ref.id,
        userId: userId,
        topicId: _selectedTopic!.topicId,
        topicTitle: _selectedTopic!.title,
        stance: _selectedStance!,
        createdAt: DateTime.now(),
      );
      await _debateRepository.createSession(session);
      return session;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
