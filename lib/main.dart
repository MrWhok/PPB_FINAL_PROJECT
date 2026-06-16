import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'firebase_options.dart';

// Data layer
import 'data/remote/ai_remote_datasource.dart';
import 'data/remote/wikipedia_remote_datasource.dart';
import 'data/remote/notification_datasource.dart';
import 'data/repository/auth_repository_impl.dart';
import 'data/repository/debate_repository_impl.dart';
import 'data/repository/topic_repository_impl.dart';
import 'data/repository/progress_repository_impl.dart';
import 'data/repository/quiz_repository_impl.dart';
import 'data/repository/profile_repository_impl.dart';

// Domain — repository interfaces (used as provider keys)
import 'domain/repository/auth_repository.dart';
import 'domain/repository/debate_repository.dart';
import 'domain/repository/topic_repository.dart';
import 'domain/repository/progress_repository.dart';
import 'domain/repository/quiz_repository.dart';
import 'domain/repository/profile_repository.dart';

// ViewModels — global (one instance for the lifetime of the app)
import 'ui/auth/login_viewmodel.dart';
import 'ui/auth/register_viewmodel.dart';
import 'ui/home/home_viewmodel.dart';
import 'ui/debate/start_debate_viewmodel.dart';
import 'ui/topics/topics_viewmodel.dart';
import 'ui/progress/progress_viewmodel.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics — catch Flutter framework errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  // Catch async errors outside Flutter (e.g. isolates, platform channels)
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Timezone data needed for scheduled notifications
  tz.initializeTimeZones();

  final notif = NotificationDatasource();
  await notif.initialize();
  await notif.scheduleDailyReminder(); // #5 — fires every day at 8 PM
  runApp(const _AppProviders());
}

class _AppProviders extends StatelessWidget {
  const _AppProviders();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- Remote datasources (plain singletons, not ChangeNotifiers) ---
        Provider<AIRemoteDatasource>(create: (_) => AIRemoteDatasource()),
        Provider<WikipediaRemoteDatasource>(
            create: (_) => WikipediaRemoteDatasource()),

        // --- Repository implementations ---
        Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        Provider<DebateRepository>(create: (_) => DebateRepositoryImpl()),
        Provider<TopicRepository>(create: (_) => TopicRepositoryImpl()),
        Provider<ProgressRepository>(create: (_) => ProgressRepositoryImpl()),
        Provider<QuizRepository>(create: (_) => QuizRepositoryImpl()),
        Provider<ProfileRepository>(create: (_) => ProfileRepositoryImpl()),

        // --- Global ViewModels ---
        ChangeNotifierProxyProvider<AuthRepository, LoginViewModel>(
          create: (ctx) =>
              LoginViewModel(repository: ctx.read<AuthRepository>()),
          update: (_, repo, prev) =>
          prev ?? LoginViewModel(repository: repo),
        ),
        ChangeNotifierProxyProvider<AuthRepository, RegisterViewModel>(
          create: (ctx) =>
              RegisterViewModel(repository: ctx.read<AuthRepository>()),
          update: (_, repo, prev) =>
          prev ?? RegisterViewModel(repository: repo),
        ),
        ChangeNotifierProxyProvider<DebateRepository, HomeViewModel>(
          create: (ctx) =>
              HomeViewModel(debateRepository: ctx.read<DebateRepository>()),
          update: (_, repo, prev) =>
          prev ?? HomeViewModel(debateRepository: repo),
        ),
        ChangeNotifierProxyProvider2<DebateRepository, TopicRepository,
            StartDebateViewModel>(
          create: (ctx) => StartDebateViewModel(
            debateRepository: ctx.read<DebateRepository>(),
            topicRepository: ctx.read<TopicRepository>(),
          ),
          update: (_, debateRepo, topicRepo, prev) =>
          prev ??
              StartDebateViewModel(
                debateRepository: debateRepo,
                topicRepository: topicRepo,
              ),
        ),
        ChangeNotifierProxyProvider<TopicRepository, TopicsViewModel>(
          create: (ctx) =>
              TopicsViewModel(repository: ctx.read<TopicRepository>()),
          update: (_, repo, prev) =>
          prev ?? TopicsViewModel(repository: repo),
        ),
        ChangeNotifierProxyProvider<ProgressRepository, ProgressViewModel>(
          create: (ctx) => ProgressViewModel(
              repository: ctx.read<ProgressRepository>()),
          update: (_, repo, prev) =>
          prev ?? ProgressViewModel(repository: repo),
        ),
      ],
      child: const DebateCoachApp(),
    );
  }
}
