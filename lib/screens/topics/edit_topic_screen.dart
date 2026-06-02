import 'package:flutter/material.dart';
import '../../models/topic.dart';
import '../../services/topic_service.dart';

class EditTopicScreen extends StatefulWidget {
  final Topic topic;

  const EditTopicScreen({super.key, required this.topic});

  @override
  State<EditTopicScreen> createState() => _EditTopicScreenState();
}

class _EditTopicScreenState extends State<EditTopicScreen> {
  final _formKey = GlobalKey<FormState>();
  final TopicService _topicService = TopicService();
  
  late String _title;
  late String _category;
  late String _difficulty;
  bool _isLoading = false;

  final List<String> _categories = [
    'Technology', 'Society', 'Economics', 'Science', 
    'Education', 'Environment', 'Ethics', 'Politics', 'General'
  ];
  
  final List<String> _difficulties = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing topic data
    _title = widget.topic.title;
    _category = _categories.contains(widget.topic.category) ? widget.topic.category : 'General';
    _difficulty = _difficulties.contains(widget.topic.difficulty) ? widget.topic.difficulty : 'medium';
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedTopic = Topic(
          topicId: widget.topic.topicId,
          title: _title,
          category: _category,
          difficulty: _difficulty,
          submittedBy: widget.topic.submittedBy,
          sourceUrl: widget.topic.sourceUrl,
        );

        await _topicService.updateTopic(updatedTopic);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Topic updated successfully!')),
          );
          Navigator.pop(context); // Go back
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating topic: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Topic'),
      ),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a topic title';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!.trim();
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                value: _category,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _category = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                ),
                value: _difficulty,
                items: _difficulties.map((String diff) {
                  return DropdownMenuItem<String>(
                    value: diff,
                    child: Text(diff.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _difficulty = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading 
                    ? const CircularProgressIndicator() 
                    : const Text('Update Topic'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
