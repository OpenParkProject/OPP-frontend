import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'login.dart';
import 'controller/issue_fine.dart';
import 'installer/totem_otp.dart';
import 'utils/totem_config_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
void showAlarmNotification() async {
  final androidDetails = AndroidNotificationDetails(
    'ticket_channel',
    'Ticket Notifications',
    channelDescription: 'Notify when ticket is about to expire or just expired',
    importance: Importance.max,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
  );

  final notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    98765,
    '📢 Alarm Triggered',
    'This notification was fired by AlarmManager.',
    notificationDetails,
    payload: 'open_ticket',
  );
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Rome'));

  final AndroidNotificationChannel channel = AndroidNotificationChannel(
  'ticket_channel', // ID
  'Ticket Notifications', // Name
  description: 'Notify when ticket is about to expire or just expired',
  importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);


  // Richiesta permessi per Android 13+ (API 33+)
    if (UniversalPlatform.isAndroid) {
      final status = await Permission.notification.status;
      await Permission.ignoreBatteryOptimizations.request();
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        if (await Permission.scheduleExactAlarm.isDenied) {
          await Permission.scheduleExactAlarm.request();
        }
        if (!result.isGranted) {
          debugPrint('⚠️ Notifications are not authorized.');
        }
      }
    }


  if (!UniversalPlatform.isWeb) {
    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: UniversalPlatform.isAndroid
            ? AndroidInitializationSettings('@mipmap/ic_launcher')
            : null,
        linux: UniversalPlatform.isLinux
            ? LinuxInitializationSettings(defaultActionName: 'Open notification')
            : null,
        windows: WindowsInitializationSettings(
          appName: 'Open Park',
          appUserModelId: 'com.openpark.app',
          guid: '12345678-1234-1234-1234-123456789abc',
        ),
      ),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload == 'open_ticket') {
          navigatorKey.currentState?.pushNamed('/tickets');
        }
      },
    );
  }


  // Carica configurazione minima
  final config = await TotemConfigManager.loadMinimalConfig();
  if (config['isTotem'] == true) {
    await clearAllPrefsExceptTotem();
  }
  final bool isTotem = config['isTotem'] == true;
  final bool configured = config['zoneId'] != null;

  Widget initialWidget;
  if (isTotem) {
    initialWidget = configured ? LoginPage() : const TotemOtpPage();
  } else {
    initialWidget = LoginPage();
  }

  runApp(ParkingApp(initialWidget: initialWidget));
}

class ParkingApp extends StatelessWidget {
  final Widget initialWidget;

  const ParkingApp({super.key, required this.initialWidget});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Open Park',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5FAFF),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFF1976D2),
          ),
        ),
      ),
      home: initialWidget,
      routes: {
        '/issue_fine': (context) => const IssueFinePage(),
      },
      navigatorObservers: [routeObserver],
    );
  }
}

Future<void> clearAllPrefsExceptTotem() async {
  final prefs = await SharedPreferences.getInstance();
  final keepKeys = {
    'isTotem',
    'zone_id',
    'zone_name',
    'latitude',
    'longitude',
    'rfid_enabled'
  };
  final allKeys = prefs.getKeys();
  for (final key in allKeys) {
    if (!keepKeys.contains(key)) {
      await prefs.remove(key);
    }
  }
}

Future<void> scheduleTicketNotifications({required int id, required DateTime end}) async {
  final tenMinutesBefore = end.subtract(Duration(minutes: 10));
  final fiveMinutesAfter = end.add(Duration(minutes: 5));

  final androidDetails = AndroidNotificationDetails(
    'ticket_channel',
    'Ticket Notifications',
    channelDescription: 'Notify when ticket is about to expire or just expired',
    importance: Importance.max,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
  );

  final notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    '⏰ Ticket expiring soon!',
    'Expires at ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
    tz.TZDateTime.from(tenMinutesBefore, tz.local),
    notificationDetails,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: null,
    payload: 'open_ticket',
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id + 1000,
    '⚠️ Ticket expired!',
    'Your parking time ended 5 minutes ago.',
    tz.TZDateTime.from(fiveMinutesAfter, tz.local),
    notificationDetails,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: null,
    payload: 'open_ticket',
  );
}

  Future<void> cancelTicketNotifications({required int id}) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    await flutterLocalNotificationsPlugin.cancel(id + 1000);
  }

  Future<void> safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    String? payload,
  }) async {
    final context = navigatorKey.currentContext;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: payload,
      );

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Scheduled exact notification ID $id at ${when.toLocal()}")),
        );
      }

    } on PlatformException catch (e) {
      debugPrint('⚠️ Exact schedule not permitted: $e');

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Exact schedule not allowed: using fallback\n$e")),
        );
      }

      // Fallback con inexact
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: null,
        payload: payload,
      );

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🟡 Fallback to inexact notification ID $id at ${when.toLocal()}")),
        );
      }

      // Mostra conferma prima di aprire impostazioni
      final confirmed = await showDialog<bool>(
        context: context!,
        builder: (context) => AlertDialog(
          title: const Text('Permission required'),
          content: const Text(
            'To schedule exact notifications, permission is required.\n'
            'Do you want to open settings to enable it?'
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Open settings'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        const intent = AndroidIntent(
          action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        );
        await intent.launch();
      } else {
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ User cancelled permission request")),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Unexpected error in safeZonedSchedule: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Unexpected error: $e")),
        );
      }
    }
  }

  void testImmediateAndScheduledNotifications() async {
    final context = navigatorKey.currentContext;
    final now = DateTime.now();

    final androidDetails = AndroidNotificationDetails(
      'ticket_channel',
      'Ticket Notifications',
      channelDescription: 'Notify when ticket is about to expire or just expired',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );
    final notificationDetails = NotificationDetails(android: androidDetails);

    // 1️⃣ Mostra notifica immediata
    await flutterLocalNotificationsPlugin.show(
      12345,
      '🔔 Immediate Notification',
      'If you see this, notifications are working.',
      notificationDetails,
      payload: 'open_ticket',
    );

    // 2️⃣ Pianifica due notifiche tra 30s e 40s
    final expiringAt = tz.TZDateTime.from(now.add(Duration(seconds: 30)), tz.local);
    final expiredAt = tz.TZDateTime.from(now.add(Duration(seconds: 40)), tz.local);

    await safeZonedSchedule(
      id: 20001,
      title: '⏰ Ticket expiring soon!',
      body: 'This ticket will expire in 10 seconds.',
      when: expiringAt,
      details: notificationDetails,
      payload: 'open_ticket',
    );

    await safeZonedSchedule(
      id: 21001,
      title: '⚠️ Ticket expired!',
      body: 'Your parking time ended just now.',
      when: expiredAt,
      details: notificationDetails,
      payload: 'open_ticket',
    );

    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Immediate + Scheduled notifications created")),
      );
    }
  }
