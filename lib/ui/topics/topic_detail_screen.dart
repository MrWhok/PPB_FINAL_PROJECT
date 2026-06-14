import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/model/topic.dart';
import '../../theme/app_theme.dart';
import 'topic_detail_viewmodel.dart';

class TopicDetailScreen extends StatefulWidget {
  final Topic topic;

  const TopicDetailScreen({super.key, required this.topic});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TopicDetailViewModel>().fetchSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TopicDetailViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Topic Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topic.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(widget.topic.category),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: AppTheme.primary),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(widget.topic.difficulty.toUpperCase()),
                  backgroundColor:
                      _difficultyColor(widget.topic.difficulty).withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                      color: _difficultyColor(widget.topic.difficulty)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.secondary),
                SizedBox(width: 8),
                Text(
                  'Background Context',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVar,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: _buildContent(vm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TopicDetailViewModel vm) {
    if (vm.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Failed to fetch background context from Wikipedia or page not found.',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.read<TopicDetailViewModel>().fetchSummary(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(vm.summary!, style: const TextStyle(fontSize: 15, height: 1.5)),
        const SizedBox(height: 12),
        const Text(
          'Source: id.wikipedia.org',
          style: TextStyle(
              fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ],
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return Colors.green;
      case 'hard': return Colors.red;
      default: return Colors.orange;
    }
  }
}
