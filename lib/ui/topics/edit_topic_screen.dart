import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/model/topic.dart';
import 'edit_topic_viewmodel.dart';

class EditTopicScreen extends StatefulWidget {
  final Topic topic;

  const EditTopicScreen({super.key, required this.topic});

  @override
  State<EditTopicScreen> createState() => _EditTopicScreenState();
}

class _EditTopicScreenState extends State<EditTopicScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late String _category;
  late String _difficulty;

  final List<String> _categories = [
    'Technology', 'Society', 'Economics', 'Science',
    'Education', 'Environment', 'Ethics', 'Politics', 'General'
  ];
  final List<String> _difficulties = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    _title = widget.topic.title;
    _category = _categories.contains(widget.topic.category)
        ? widget.topic.category
        : 'General';
    _difficulty = _difficulties.contains(widget.topic.difficulty)
        ? widget.topic.difficulty
        : 'medium';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final updatedTopic = Topic(
      topicId: widget.topic.topicId,
      title: _title,
      category: _category,
      difficulty: _difficulty,
      submittedBy: widget.topic.submittedBy,
      sourceUrl: widget.topic.sourceUrl,
    );

    final vm = context.read<EditTopicViewModel>();
    final success = await vm.updateTopic(updatedTopic);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topic updated successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating topic. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<EditTopicViewModel>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Topic')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: 'Topic Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Please enter a topic title' : null,
                onSaved: (v) => _title = v!.trim(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                initialValue: _category,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                ),
                initialValue: _difficulty,
                items: _difficulties
                    .map((d) => DropdownMenuItem(
                        value: d, child: Text(d.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _difficulty = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Update Topic'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
