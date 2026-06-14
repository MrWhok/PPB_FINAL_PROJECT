import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../domain/model/topic.dart';
import '../../domain/repository/topic_repository.dart';
import '../../data/remote/wikipedia_remote_datasource.dart';
import 'topics_viewmodel.dart';
import 'add_topic_screen.dart';
import 'add_topic_viewmodel.dart';
import 'edit_topic_screen.dart';
import 'edit_topic_viewmodel.dart';
import 'topic_detail_screen.dart';
import 'topic_detail_viewmodel.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All', 'Technology', 'Society', 'Economics', 'Science',
    'Education', 'Environment', 'Ethics', 'Politics', 'General'
  ];

  void _seedData() async {
    try {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Seeding data...')));
      await context.read<TopicsViewModel>().seedSampleTopics(kSampleTopics);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data seeded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error seeding data: $e')));
      }
    }
  }

  void _confirmDelete(Topic topic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Topik?'),
        content: Text(
            'Apakah Anda yakin ingin menghapus topik "${topic.title}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<TopicsViewModel>().deleteTopic(topic.topicId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Topik "${topic.title}" berhasil dihapus.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus topik: $e')),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Topic topic) {
    final wikiDatasource = context.read<WikipediaRemoteDatasource>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => TopicDetailViewModel(
            topicTitle: topic.title,
            datasource: wikiDatasource,
          ),
          child: TopicDetailScreen(topic: topic),
        ),
      ),
    );
  }

  void _navigateToAdd() {
    final topicRepo = context.read<TopicRepository>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => AddTopicViewModel(repository: topicRepo),
          child: const AddTopicScreen(),
        ),
      ),
    );
  }

  void _navigateToEdit(Topic topic) {
    final topicRepo = context.read<TopicRepository>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => EditTopicViewModel(repository: topicRepo),
          child: EditTopicScreen(topic: topic),
        ),
      ),
    );
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
            onPressed: _seedData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search topics',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              initialValue: _selectedCategory,
              items: _categories
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Topic>>(
              stream: context.read<TopicsViewModel>().topicsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No topics found. Add some or click the seed button!'));
                }

                final filtered = snapshot.data!.where((t) {
                  final matchSearch =
                      t.title.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchCat = _selectedCategory == 'All' ||
                      t.category == _selectedCategory;
                  return matchSearch && matchCat;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No topics match your filters.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final topic = filtered[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        onTap: () => _navigateToDetail(topic),
                        title: Text(topic.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${topic.category} • ${topic.difficulty.toUpperCase()}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: AppTheme.secondary),
                              onPressed: () => _navigateToEdit(topic),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(topic),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}
