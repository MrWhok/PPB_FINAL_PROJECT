import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'domain/repository/auth_repository.dart';
import 'theme/app_theme.dart';
import 'ui/main_scaffold.dart';
import 'ui/auth/login_screen.dart';

class DebateCoachApp extends StatelessWidget {
  const DebateCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DebateCoach',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const _AuthWrapper(),
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<AuthRepository>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }
        if (snapshot.hasData) return const MainScaffold();
        return const LoginScreen();
      },
    );
  }
}
