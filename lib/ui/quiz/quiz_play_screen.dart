import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import 'quiz_viewmodel.dart';
import 'quiz_result_screen.dart';

class QuizPlayScreen extends StatelessWidget {
  const QuizPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (vm.error != null && vm.questions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('QUIZ')),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(vm.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary)),
              ),
            ),
          );
        }

        final q = vm.currentQuestion!;
        final selected = vm.selectedFor(vm.currentIndex);
        final progress = (vm.currentIndex + 1) / vm.total;

        return Scaffold(
          appBar: AppBar(
            title: Text('${vm.currentIndex + 1} / ${vm.total}'),
          ),
          body: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.surfaceVar,
                color: AppTheme.primary,
                minHeight: 4,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          q.category.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        q.question,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...List.generate(q.options.length, (i) {
                        final isSelected = selected == i;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => vm.selectAnswer(i),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withValues(alpha: 0.12)
                                    : AppTheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppTheme.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                    child: Text(
                                      String.fromCharCode(65 + i), // A,B,C,D
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      q.options[i],
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              _NavBar(vm: vm),
            ],
          ),
        );
      },
    );
  }
}

class _NavBar extends StatelessWidget {
  final QuizViewModel vm;
  const _NavBar({required this.vm});

  void _finish(BuildContext context) async {
    await vm.submit();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(vm: vm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answered = vm.selectedFor(vm.currentIndex) != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          if (vm.currentIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: vm.previous,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: const Text('BACK',
                    style: TextStyle(color: AppTheme.textPrimary)),
              ),
            ),
          if (vm.currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: !answered
                  ? null
                  : vm.isLastQuestion
                      ? () => _finish(context)
                      : vm.next,
              child: Text(vm.isLastQuestion ? 'FINISH' : 'NEXT'),
            ),
          ),
        ],
      ),
    );
  }
}
