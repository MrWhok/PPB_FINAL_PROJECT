import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'debate/start_debate_screen.dart';
import 'topics/topics_screen.dart';
import 'progress/progress_screen.dart';
import 'quiz/quiz_hub_screen.dart';
import 'quiz/quiz_history_viewmodel.dart';
import '../domain/repository/quiz_repository.dart';
import '../theme/app_theme.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  void _goToDebate() => setState(() => _currentIndex = 1);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final screens = [
      HomeScreen(onNavigateToDebate: _goToDebate),
      const StartDebateScreen(),
      const TopicsScreen(),
      ChangeNotifierProvider(
        create: (ctx) => QuizHistoryViewModel(
          repository: ctx.read<QuizRepository>(),
          userId: userId,
        ),
        child: QuizHubScreen(userId: userId),
      ),
      const ProgressScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.gavel_outlined),
              activeIcon: Icon(Icons.gavel),
              label: 'Debate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books),
              label: 'Topics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz_outlined),
              activeIcon: Icon(Icons.quiz),
              label: 'Quiz',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: 'Progress',
            ),
          ],
        ),
      ),
    );
  }
}
