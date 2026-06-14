import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationDatasource {
  static final NotificationDatasource _instance =
      NotificationDatasource._internal();
  factory NotificationDatasource() => _instance;
  NotificationDatasource._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isFirstSnapshot = true;

  // Fixed IDs so each notification type replaces its own previous instance
  static const int _idTopicAdded = 0;
  static const int _idScoreReady = 1;
  static const int _idHighScore = 2;
  static const int _idSessionDeleted = 3;
  static const int _idDailyReminder = 100;

  Future<void> initialize() async {
    // v22: initialize() requires `settings:` as a named parameter
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Existing: notify when Person B adds a new topic
    FirebaseFirestore.instance
        .collection('topics')
        .snapshots()
        .listen((snapshot) {
      if (_isFirstSnapshot) {
        _isFirstSnapshot = false;
        return;
      }
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['title'] != null) {
            _show(
              id: _idTopicAdded,
              title: 'Topik Baru!',
              body: 'Topik "${data['title']}" telah ditambahkan ke library.',
              channelId: 'basic_channel',
              channelName: 'Basic Notifications',
            );
          }
        }
      }
    });
  }

  // --- Notification #1: Score Ready ---
  Future<void> showScoreReady(int score, String topicTitle) => _show(
        id: _idScoreReady,
        title: 'Debate Scored! 🎯',
        body: '"$topicTitle" scored $score/10. Check your feedback!',
        channelId: 'debate_channel',
        channelName: 'Debate Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

  // --- Notification #2: Session Deleted ---
  Future<void> showSessionDeleted(String topicTitle) => _show(
        id: _idSessionDeleted,
        title: 'Session Deleted',
        body: '"$topicTitle" has been removed from your history.',
        channelId: 'debate_channel',
        channelName: 'Debate Notifications',
      );

  // --- Notification #3: High Score Achievement (score >= 8) ---
  Future<void> showHighScore(int score) => _show(
        id: _idHighScore,
        title: 'Great Performance! 🔥',
        body: 'You scored $score/10 — one of your best debates yet!',
        channelId: 'debate_channel',
        channelName: 'Debate Notifications',
        importance: Importance.max,
        priority: Priority.max,
      );

  // --- Notification #5: Daily Practice Reminder at 8 PM ---
  Future<void> scheduleDailyReminder() async {
    // v22: cancel() requires `id:` as a named parameter
    await _plugin.cancel(id: _idDailyReminder);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Daily Reminders',
      channelDescription: 'Daily practice reminder at 8 PM',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(
        "You haven't debated today. Keep your streak alive!",
      ),
    );

    // v22: zonedSchedule() uses all named parameters
    await _plugin.zonedSchedule(
      id: _idDailyReminder,
      title: 'Time to Debate! ⚔️',
      body: "You haven't debated today. Keep your streak alive!",
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // --- Internal helper ---
  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority,
      showWhen: true,
      // BigTextStyleInformation makes the notification expandable on pull-down
      // so the full body text is always visible
      styleInformation: BigTextStyleInformation(body),
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }
}
