import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_scaffold.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase not configured yet — UI renders but Firestore saves won't work.
    // Run "flutterfire configure" to fix this.
    debugPrint('Firebase init skipped: $e');
  }
  runApp(const DebateCoachApp());
}

class DebateCoachApp extends StatelessWidget {
  const DebateCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DebateCoach',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const MainScaffold(),
    );
  }
}
