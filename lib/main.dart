import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'login.dart';
import 'debug/debug.dart';
import 'API/client.dart';
import 'config.dart';

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
    assert(() {
      debugPrint('Error in ticket sync: $e');
      return true;
    }());
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
          android: UniversalPlatform.isAndroid ? AndroidNotificationDetails(
            'ticket_channel',
            'Ticket Notifications',
            channelDescription: 'Notify when ticket is about to expire',
            importance: Importance.max,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
            usesChronometer: true,
            showWhen: true,
          ) : null,
          linux: UniversalPlatform.isLinux ? LinuxNotificationDetails(
            defaultActionName: "Open",
            suppressSound: false,
            urgency: LinuxNotificationUrgency.normal,
          ) : null,
        ),
        payload: 'open_ticket',
      );
      notifiedIds.add(id);
    }

    if (diff < 0 && diff >= -5 && !notifiedIds.contains("expired_$id")) {
      await flutterLocalNotificationsPlugin.show(
        id.hashCode + 1000, // Different ID to avoid conflicts
        '⚠️ Ticket expired!',
        'Your parking time ended ${-diff} minutes ago.',
        NotificationDetails(
          android: UniversalPlatform.isAndroid ? AndroidNotificationDetails(
            'expired_channel',
            'Expired Tickets',
            channelDescription: 'Notify when ticket has just expired',
            importance: Importance.max,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
          ) : null,
          linux: UniversalPlatform.isLinux ? LinuxNotificationDetails(
            defaultActionName: "Open",
            suppressSound: false,
            urgency: LinuxNotificationUrgency.critical,
          ) : null,
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
    // Web-specific code
  } else if (UniversalPlatform.isAndroid) {
      await AndroidAlarmManager.initialize();
      await AndroidAlarmManager.periodic(
        const Duration(minutes: 5),
        0,
        checkExpiringTickets,
        wakeup: true,
        rescheduleOnReboot: true,
      );
  } else if (UniversalPlatform.isLinux) {
    Timer.periodic(const Duration(minutes: 5), (_) {
      checkExpiringTickets();
    });
  } else {
    throw UnsupportedError('Unsupported platform');
  }
  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      // Add Linux settings
      linux: const LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      ),
    ),
    onDidReceiveNotificationResponse: (details) {
      if (details.payload == 'open_ticket') {
        navigatorKey.currentState?.pushNamed('/tickets');
      }
    },
  );

  runApp(ParkingApp());
}

class ParkingApp extends StatelessWidget {
  const ParkingApp({super.key});

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
      home: debugMode ? const DebugRoleSelector() : LoginPage(),
    );
  }
}