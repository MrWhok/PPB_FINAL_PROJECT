import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../domain/model/quiz_attempt.dart';
import '../../domain/repository/quiz_repository.dart';
import 'quiz_history_viewmodel.dart';
import 'quiz_viewmodel.dart';
import 'quiz_play_screen.dart';

class QuizHubScreen extends StatelessWidget {
  final String userId;
  const QuizHubScreen({super.key, required this.userId});

  static const _categories = [
    ('Mixed', Icons.shuffle, 'All categories combined'),
    ('Logical Fallacy', Icons.psychology_alt, 'Spot the reasoning errors'),
    ('Debate Technique', Icons.record_voice_over, 'Master the craft'),
    ('Topic', Icons.public, 'Test your topic knowledge'),
  ];

  void _startQuiz(BuildContext context, String category) {
    final repo = context.read<QuizRepository>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) =>
              QuizViewModel(repository: repo, userId: userId)
                ..loadQuiz(category: category),
          child: const QuizPlayScreen(),
        ),
      ),
    );
  }

  void _seed(BuildContext context, QuizHistoryViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Seeding quiz bank...')));
    try {
      await vm.seedQuestions();
      messenger.showSnackBar(
          const SnackBar(content: Text('Quiz bank seeded successfully!')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error seeding: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<QuizHistoryViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('QUIZ ARENA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Seed Quiz Bank',
            onPressed: () => _seed(context, vm),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose a category',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Each round has up to 5 multiple-choice questions.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ..._categories.map((c) => _CategoryCard(
                label: c.$1,
                icon: c.$2,
                subtitle: c.$3,
                onTap: () => _startQuiz(context, c.$1),
              )),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.history, color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Your History',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<QuizAttempt>>(
            stream: vm.attemptsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                );
              }
              final attempts = snapshot.data ?? [];
              if (attempts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No attempts yet. Take your first quiz!',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                );
              }
              return Column(
                children: attempts
                    .map((a) => _AttemptCard(attempt: a, vm: vm))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppTheme.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final QuizAttempt attempt;
  final QuizHistoryViewModel vm;

  const _AttemptCard({required this.attempt, required this.vm});

  Color get _scoreColor {
    final p = attempt.percentage;
    if (p >= 80) return AppTheme.proColor;
    if (p >= 50) return AppTheme.secondary;
    return AppTheme.conColor;
  }

  void _editNote(BuildContext context) {
    final controller = TextEditingController(text: attempt.note);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'What did you learn from this attempt?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await vm.updateNote(attempt.attemptId, controller.text.trim());
                messenger.showSnackBar(
                    const SnackBar(content: Text('Note updated.')));
              } catch (e) {
                messenger.showSnackBar(
                    SnackBar(content: Text('Failed to update note: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Attempt?'),
        content: const Text(
            'This quiz result will be permanently removed from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await vm.deleteAttempt(attempt.attemptId);
                messenger.showSnackBar(
                    const SnackBar(content: Text('Attempt deleted.')));
              } catch (e) {
                messenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy, HH:mm').format(attempt.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${attempt.score}/${attempt.total}',
                    style: TextStyle(
                      color: _scoreColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(attempt.category,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                      Text(dateStr,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note,
                      color: AppTheme.secondary, size: 22),
                  tooltip: 'Edit note',
                  onPressed: () => _editNote(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 22),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            if (attempt.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVar,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  attempt.note,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
