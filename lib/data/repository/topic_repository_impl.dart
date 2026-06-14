import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repository/topic_repository.dart';
import '../../domain/model/topic.dart';

class TopicRepositoryImpl implements TopicRepository {
  final _firestore = FirebaseFirestore.instance;
  static const _collection = 'topics';

  @override
  Stream<List<Topic>> getTopics() {
    return _firestore.collection(_collection).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Topic.fromMap(doc.data())).toList());
  }

  @override
  Future<void> addTopic(Topic topic) async {
    final docRef = topic.topicId.isEmpty
        ? _firestore.collection(_collection).doc()
        : _firestore.collection(_collection).doc(topic.topicId);

    final topicToSave = Topic(
      topicId: docRef.id,
      title: topic.title,
      category: topic.category,
      difficulty: topic.difficulty,
      submittedBy: topic.submittedBy,
      sourceUrl: topic.sourceUrl,
    );
    await docRef.set(topicToSave.toMap());
  }

  @override
  Future<void> updateTopic(Topic topic) async {
    await _firestore.collection(_collection).doc(topic.topicId).update(topic.toMap());
  }

  @override
  Future<void> deleteTopic(String topicId) async {
    await _firestore.collection(_collection).doc(topicId).delete();
  }

  @override
  Future<void> seedSampleTopics(List<Topic> topics) async {
    final batch = _firestore.batch();
    for (final topic in topics) {
      final docRef = _firestore.collection(_collection).doc(topic.topicId);
      batch.set(docRef, topic.toMap());
    }
    await batch.commit();
  }
}
