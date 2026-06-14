import 'package:flutter/foundation.dart';
import '../../domain/model/topic.dart';
import '../../domain/repository/topic_repository.dart';

class EditTopicViewModel extends ChangeNotifier {
  final TopicRepository _repository;

  EditTopicViewModel({required TopicRepository repository})
      : _repository = repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> updateTopic(Topic topic) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateTopic(topic);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
