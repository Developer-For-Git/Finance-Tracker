import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    await _createChannel();
    _initialized = true;
  }

  static Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      'ather_reminders', 'Daily Reminders',
      description: 'Daily expense logging reminders',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> scheduleDailyReminder(int hour, int minute) async {
    await _plugin.cancelAll();
    await _plugin.periodicallyShow(
      0,
      '💰 Ather Wallet',
      'Don\'t forget to log your expenses today!',
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ather_reminders', 'Daily Reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();
}
