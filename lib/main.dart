import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'login.dart';
import 'db/db_zones.dart';
import 'controller/issue_fine.dart';
import 'debug/debug_role_selector.dart';
import 'singleton/dio_client.dart';
import 'driver/layout.dart';
import 'config.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ZoneDB.loadZones();

  if (kIsWeb) {
    // Web-specific code
  } else if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
      await AndroidAlarmManager.periodic(
        const Duration(minutes: 5),
        0,
        checkExpiringTickets,
        wakeup: true,
        rescheduleOnReboot: true,
      );
  } else {
    // Other platforms
  }

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
        scaffoldBackgroundColor: Color(0xFFF5FAFF),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFF1976D2),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
      ),
      routes: {
        '/issue_fine': (context) => const IssueFinePage(),
        '/tickets': (context) => MainUserHomePage(username: "User"),
      },
      home: StartupRouter(),
    );
  }
}

class StartupRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initAndRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return snapshot.data as Widget;
      },
    );
  }

  Future<Widget> _initAndRoute() async {
    if (debugMode) {
      return DebugRoleSelector(); // <<-- bypass login in debug mode
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final remember = prefs.getBool('remember_me') ?? false;

    if (remember && token != null) {
      await DioClient().setAuthToken();
      final userRes = await DioClient().dio.get('/users/me');
      final username = userRes.data['username'];
      return MainUserHomePage(username: username);
    }

    return LoginPage();
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
          android: AndroidNotificationDetails(
            'ticket_channel',
            'Ticket Notifications',
            channelDescription: 'Notify when ticket is about to expire',
            importance: Importance.max,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
            usesChronometer: true,
            showWhen: true,
          ),
        ),
        payload: 'open_ticket',
      );
      notifiedIds.add(id);
    }

    if (diff < 0 && diff >= -5 && !notifiedIds.contains("expired_$id")) {
      await flutterLocalNotificationsPlugin.show(
        id.hashCode,
        '⚠️ Ticket expired!',
        'Your parking time ended ${-diff} minutes ago.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expired_channel',
            'Expired Tickets',
            channelDescription: 'Notify when ticket has just expired',
            importance: Importance.max,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
          ),
        ),
        payload: 'open_ticket',
      );
      notifiedIds.add("expired_$id");
    }
  }

  await prefs.setStringList('notified_ticket_ids', notifiedIds);
}
