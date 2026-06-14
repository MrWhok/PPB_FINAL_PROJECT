import 'package:flutter/foundation.dart';
import '../../domain/model/topic.dart';
import '../../domain/repository/topic_repository.dart';

class TopicsViewModel extends ChangeNotifier {
  final TopicRepository _repository;

  TopicsViewModel({required TopicRepository repository})
      : _repository = repository;

  late final Stream<List<Topic>> _topicsStream = _repository.getTopics();
  Stream<List<Topic>> get topicsStream => _topicsStream;

  Future<void> deleteTopic(String topicId) => _repository.deleteTopic(topicId);

  Future<void> addTopic(Topic topic) => _repository.addTopic(topic);

  Future<void> updateTopic(Topic topic) => _repository.updateTopic(topic);

  Future<void> seedSampleTopics(List<Topic> topics) =>
      _repository.seedSampleTopics(topics);
}
