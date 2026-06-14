import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationDatasource {
  static final NotificationDatasource _instance = NotificationDatasource._internal();
  factory NotificationDatasource() => _instance;
  NotificationDatasource._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isFirstSnapshot = true;

  Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    FirebaseFirestore.instance.collection('topics').snapshots().listen((snapshot) {
      if (_isFirstSnapshot) {
        _isFirstSnapshot = false;
        return;
      }
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['title'] != null) {
            _showNotification(
                'Topik Baru!', 'Topik "${data['title']}" telah ditambahkan ke library.');
          }
        }
      }
    });
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'basic_channel',
      'Basic notifications',
      channelDescription: 'Notification channel for basic tests',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }
}
