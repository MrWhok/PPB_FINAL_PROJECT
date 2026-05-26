import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/topic.dart';

class TopicService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'topics';

  Future<void> addTopic(Topic topic) async {
    try {
      // Use the provided topicId or generate a new one via Firestore
      final docRef = topic.topicId.isEmpty 
          ? _firestore.collection(_collectionName).doc() 
          : _firestore.collection(_collectionName).doc(topic.topicId);
      
      // Update the topicId in the model if it was newly generated
      final topicToSave = Topic(
        topicId: docRef.id,
        title: topic.title,
        category: topic.category,
        difficulty: topic.difficulty,
        submittedBy: topic.submittedBy,
        sourceUrl: topic.sourceUrl,
      );

      await docRef.set(topicToSave.toMap());
    } catch (e) {
      throw Exception('Failed to add topic: $e');
    }
  }

  Future<void> seedSampleTopics(List<Topic> topics) async {
    try {
      final batch = _firestore.batch();
      
      for (var topic in topics) {
        final docRef = _firestore.collection(_collectionName).doc(topic.topicId);
        batch.set(docRef, topic.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to seed topics: $e');
    }
  }
}
