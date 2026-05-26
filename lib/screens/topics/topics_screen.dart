import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'add_topic_screen.dart';
import '../../services/topic_service.dart';
import '../../models/topic.dart';

// Person B feature — Topic Library (Week 1)
class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  void _seedData(BuildContext context) async {
    final topicService = TopicService();
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seeding data...')),
      );
      await topicService.seedSampleTopics(kSampleTopics);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data seeded successfully! Check Firestore.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error seeding data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOPIC LIBRARY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Seed Sample Data',
            onPressed: () => _seedData(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.library_books,
                    color: AppTheme.secondary, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'TOPIC LIBRARY',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'PERSON B',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Browse, search, add, edit, and delete debate topics.\nComing in Week 1 from Person B.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTopicScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
