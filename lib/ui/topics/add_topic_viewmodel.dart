import 'package:flutter/foundation.dart';
import '../../domain/model/topic.dart';
import '../../domain/repository/topic_repository.dart';

class AddTopicViewModel extends ChangeNotifier {
  final TopicRepository _repository;

  AddTopicViewModel({required TopicRepository repository})
      : _repository = repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> addTopic({
    required String title,
    required String category,
    required String difficulty,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final topic = Topic(
        topicId: '',
        title: title,
        category: category,
        difficulty: difficulty,
      );
      await _repository.addTopic(topic);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
