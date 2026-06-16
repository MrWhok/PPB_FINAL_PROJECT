import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'quiz_viewmodel.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizViewModel vm;
  const QuizResultScreen({super.key, required this.vm});

  Color get _scoreColor {
    final p = vm.total == 0 ? 0 : (vm.score / vm.total) * 100;
    if (p >= 80) return AppTheme.proColor;
    if (p >= 50) return AppTheme.secondary;
    return AppTheme.conColor;
  }

  String get _message {
    final p = vm.total == 0 ? 0 : (vm.score / vm.total) * 100;
    if (p == 100) return 'Flawless! You\'re a master debater.';
    if (p >= 80) return 'Excellent work!';
    if (p >= 50) return 'Good effort — keep practising.';
    return 'Review the explanations and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RESULT'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _scoreColor.withValues(alpha: 0.12),
                    border: Border.all(color: _scoreColor, width: 3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${vm.score}',
                        style: TextStyle(
                          color: _scoreColor,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      Text(
                        'of ${vm.total}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Review',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(vm.questions.length, (i) {
            final q = vm.questions[i];
            final picked = vm.selectedFor(i);
            final correct = picked == q.correctIndex;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          correct ? Icons.check_circle : Icons.cancel,
                          color: correct
                              ? AppTheme.proColor
                              : AppTheme.conColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q.question,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (!correct && picked != null)
                      _AnswerLine(
                        label: 'Your answer',
                        text: q.options[picked],
                        color: AppTheme.conColor,
                      ),
                    _AnswerLine(
                      label: 'Correct answer',
                      text: q.options[q.correctIndex],
                      color: AppTheme.proColor,
                    ),
                    if (q.explanation.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVar,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          q.explanation,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BACK TO QUIZ ARENA'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  const _AnswerLine(
      {required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
