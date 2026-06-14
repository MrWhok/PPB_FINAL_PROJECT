import '../model/topic.dart';

abstract interface class TopicRepository {
  Stream<List<Topic>> getTopics();
  Future<void> addTopic(Topic topic);
  Future<void> updateTopic(Topic topic);
  Future<void> deleteTopic(String topicId);
  Future<void> seedSampleTopics(List<Topic> topics);
}
