class Topic {
  final String topicId;
  final String title;
  final String category;
  final String difficulty;
  final String submittedBy;
  final String sourceUrl;

  const Topic({
    required this.topicId,
    required this.title,
    required this.category,
    required this.difficulty,
    this.submittedBy = 'system',
    this.sourceUrl = '',
  });

  Map<String, dynamic> toMap() => {
        'topicId': topicId,
        'title': title,
        'category': category,
        'difficulty': difficulty,
        'submittedBy': submittedBy,
        'sourceUrl': sourceUrl,
      };

  factory Topic.fromMap(Map<String, dynamic> map) => Topic(
        topicId: map['topicId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        category: map['category'] as String? ?? 'General',
        difficulty: map['difficulty'] as String? ?? 'medium',
        submittedBy: map['submittedBy'] as String? ?? 'system',
        sourceUrl: map['sourceUrl'] as String? ?? '',
      );
}

// Hardcoded for Week 1 — will be fetched from Firestore topics/ in Week 2
const List<Topic> kSampleTopics = [
  Topic(topicId: 't1', title: 'AI will replace most human jobs within a decade', category: 'Technology', difficulty: 'medium'),
  Topic(topicId: 't2', title: 'Social media does more harm than good to society', category: 'Society', difficulty: 'easy'),
  Topic(topicId: 't3', title: 'Universal basic income should be implemented globally', category: 'Economics', difficulty: 'hard'),
  Topic(topicId: 't4', title: 'Space exploration is worth the massive investment', category: 'Science', difficulty: 'medium'),
  Topic(topicId: 't5', title: 'Online education is superior to traditional schooling', category: 'Education', difficulty: 'easy'),
  Topic(topicId: 't6', title: 'Nuclear energy is the best solution to climate change', category: 'Environment', difficulty: 'hard'),
  Topic(topicId: 't7', title: 'Smartphones are making us intellectually weaker', category: 'Technology', difficulty: 'easy'),
  Topic(topicId: 't8', title: 'Zoos should be abolished to protect animal rights', category: 'Ethics', difficulty: 'medium'),
  Topic(topicId: 't9', title: 'Developed nations should open their borders to all immigrants', category: 'Politics', difficulty: 'hard'),
  Topic(topicId: 't10', title: 'Vegetarianism should be mandatory to save the planet', category: 'Environment', difficulty: 'medium'),
];
