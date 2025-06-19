import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'driver/driver_layout.dart';
import 'main.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotification() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();

  const LinuxInitializationSettings linuxSettings =
      LinuxInitializationSettings(defaultActionName: 'Open notification');

  const WindowsInitializationSettings windowsSettings =
      WindowsInitializationSettings(
    appName: 'OpenPark',
    appUserModelId: 'com.openpark.desktop',
    guid: 'b9f3d5fc-7585-4b23-ae67-34e26f028e44',
  );

  final InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
    linux: linuxSettings,
    windows: windowsSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload == 'open_ticket') {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const MainUserHomePage(username: 'debug_driver'),
          ),
          (route) => false,
        );
      }
    },
  );

  // Registers channel with sound and vibration
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
    'ticket_channel',
    'Ticket Notifications',
    description: 'Notify when ticket is about to expire or just expired',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alert_notification'), // alert.mp3
  ));
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
    NotificationDetails(
      android: AndroidNotificationDetails(
        'ticket_channel',
        'Ticket Notifications',
        channelDescription: 'Notify when ticket is about to expire or just expired',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alert'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 1000, 500, 1000, 500, 2000]),
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: null,
    payload: 'open_ticket',
  );

  final pending =
      await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  debugPrint('[DEBUG] Notifiche pending: ${pending.length}');
  for (final p in pending) {
    debugPrint('[DEBUG] ID=${p.id}, title=${p.title}, body=${p.body}');
  }
}
