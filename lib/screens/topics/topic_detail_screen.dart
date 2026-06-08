import 'package:flutter/material.dart';
import '../../models/topic.dart';
import '../../services/wikipedia_service.dart';
import '../../theme/app_theme.dart';

class TopicDetailScreen extends StatefulWidget {
  final Topic topic;

  const TopicDetailScreen({super.key, required this.topic});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  final WikipediaService _wikipediaService = WikipediaService();
  String? _summary;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final summary = await _wikipediaService.getSummary(widget.topic.title);
    
    if (mounted) {
      setState(() {
        _summary = summary;
        _isLoading = false;
        if (summary == null) {
          _hasError = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.topic.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Badges for Category and Difficulty
            Row(
              children: [
                Chip(
                  label: Text(widget.topic.category),
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppTheme.primary),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(widget.topic.difficulty.toUpperCase()),
                  backgroundColor: _getDifficultyColor(widget.topic.difficulty).withOpacity(0.1),
                  labelStyle: TextStyle(color: _getDifficultyColor(widget.topic.difficulty)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Wikipedia Context Section
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.secondary),
                SizedBox(width: 8),
                Text(
                  'Background Context',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Wikipedia Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVar,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: _buildWikipediaContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWikipediaContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_hasError || _summary == null || _summary!.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Failed to fetch background context from Wikipedia or page not found.',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _fetchSummary,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _summary!,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Source: id.wikipedia.org',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
