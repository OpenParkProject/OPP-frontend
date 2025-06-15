import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotification() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

  Future<void> scheduleNotification({
    int id = 888,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final rome = tz.getLocation('Europe/Rome');
    final scheduled = tz.TZDateTime.from(scheduledDate, rome);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ticket_channel',
          'Ticket Notifications',
          channelDescription: 'Notify when ticket is about to expire or just expired',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      payload: 'open_ticket',
    );

    // ✅ DEBUG: Verifica se la notifica è stata registrata
    final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    print('[DEBUG] Notifiche pending: ${pending.length}');
    for (final p in pending) {
      print('[DEBUG] ID=${p.id}, title=${p.title}, body=${p.body}');
    }
  }
