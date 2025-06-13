import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'login.dart';
import 'API/client.dart';
import 'controller/issue_fine.dart';
import 'installer/totem_otp.dart';
import 'utils/totem_config_manager.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> syncAndCheckTickets() async {
  final prefs = await SharedPreferences.getInstance();
  try {
    final response = await DioClient().dio.get('/users/me/tickets');
    final allTickets = List<Map<String, dynamic>>.from(response.data);

    final now = DateTime.now();
    final stillValid = allTickets.where((t) {
      final end = DateTime.tryParse(t['end_time'] ?? '');
      return end != null && end.isAfter(now);
    }).toList();

    await prefs.setString('local_tickets', jsonEncode(stillValid));
    await checkExpiringTickets();
  } catch (e) {
    debugPrint('Error in ticket sync: $e');
  }
}

Future<void> checkExpiringTickets() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('local_tickets');
  if (raw == null) return;

  final List<dynamic> tickets = jsonDecode(raw);
  final now = DateTime.now();
  final notifiedIds = prefs.getStringList('notified_ticket_ids') ?? [];

  for (final t in tickets) {
    final id = t['id'].toString();
    final end = DateTime.tryParse(t['end_time']);
    if (end == null) continue;

    final diff = end.difference(now).inMinutes;

    if (diff <= 10 && diff >= 0 && !notifiedIds.contains(id)) {
      await flutterLocalNotificationsPlugin.show(
        id.hashCode,
        '⏰ Ticket expiring soon!',
        'Expires at ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
        NotificationDetails(
          android: UniversalPlatform.isAndroid
              ? AndroidNotificationDetails(
                  'ticket_channel',
                  'Ticket Notifications',
                  channelDescription: 'Notify when ticket is about to expire',
                  importance: Importance.max,
                  priority: Priority.high,
                  visibility: NotificationVisibility.public,
                  usesChronometer: true,
                  showWhen: true,
                )
              : null,
          linux: UniversalPlatform.isLinux
              ? LinuxNotificationDetails(
                  defaultActionName: "Open",
                  suppressSound: false,
                  urgency: LinuxNotificationUrgency.normal,
                )
              : null,
        ),
        payload: 'open_ticket',
      );
      notifiedIds.add(id);
    }

    if (diff < 0 && diff >= -5 && !notifiedIds.contains("expired_$id")) {
      await flutterLocalNotificationsPlugin.show(
        id.hashCode + 1000,
        '⚠️ Ticket expired!',
        'Your parking time ended ${-diff} minutes ago.',
        NotificationDetails(
          android: UniversalPlatform.isAndroid
              ? AndroidNotificationDetails(
                  'expired_channel',
                  'Expired Tickets',
                  channelDescription: 'Notify when ticket has just expired',
                  importance: Importance.max,
                  priority: Priority.high,
                  visibility: NotificationVisibility.public,
                )
              : null,
          linux: UniversalPlatform.isLinux
              ? LinuxNotificationDetails(
                  defaultActionName: "Open",
                  suppressSound: false,
                  urgency: LinuxNotificationUrgency.critical,
                )
              : null,
        ),
        payload: 'open_ticket',
      );
      notifiedIds.add("expired_$id");
    }
  }

  await prefs.setStringList('notified_ticket_ids', notifiedIds);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  if (UniversalPlatform.isWeb) {
    // Web non supporta notifiche native
  } else if (UniversalPlatform.isAndroid) {
    await AndroidAlarmManager.initialize();
    await AndroidAlarmManager.periodic(
      const Duration(minutes: 5),
      0,
      checkExpiringTickets,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  } else if (UniversalPlatform.isLinux || UniversalPlatform.isWindows) {
    Timer.periodic(const Duration(minutes: 5), (_) => checkExpiringTickets());
  } else {
    debugPrint('Piattaforma non supportata, niente ticket checker');
  }

  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      linux: const LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      ),
      windows: const WindowsInitializationSettings(
        appName: 'OpenPark',
        appUserModelId: 'com.openpark.app',
        guid: '12345678-1234-1234-1234-1234567890ab',
      ),
    ),
    onDidReceiveNotificationResponse: (details) {
      if (details.payload == 'open_ticket') {
        navigatorKey.currentState?.pushNamed('/tickets');
      }
    },
  );

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
