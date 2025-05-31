import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
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
  tz.initializeTimeZones();
  await ZoneDB.loadZones();

  if (Platform.isAndroid) {
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  if (androidInfo.version.sdkInt >= 33) {
    await Permission.notification.request();
    }
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1976D2),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
      ),
      routes: {
        '/issue_fine': (context) => const IssueFinePage(),
        '/tickets': (context) => const MainUserHomePage(username: "User"),
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
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.data == null) {
          return const Center(child: Text('Something went wrong'));
        }
        return snapshot.data as Widget;
      },
    );
  }

  Future<Widget> _initAndRoute() async {
    if (debugMode) {
      return const DebugRoleSelector(); // Debug mode
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final remember = prefs.getBool('remember_me') ?? false;

    if (remember && token != null) {
      try {
        await DioClient().setAuthToken();

        // DEBUG: stampiamo gli header per verificare se il token è ben formato
        debugPrint('Authorization header: ${DioClient().dio.options.headers['Authorization']}');

        final userRes = await DioClient().dio.get('/users/me');

        // Se il server risponde 200, prosegui
        if (userRes.statusCode == 200) {
          final username = userRes.data['username'];
          await syncAndCheckTickets();
          return MainUserHomePage(username: username);
        } else {
          debugPrint('Server returned ${userRes.statusCode}: ${userRes.data}');
        }

      } on DioError catch (e) {
        // Server ha risposto con 400 o simili
        debugPrint('❌ DioException while calling /users/me');
        debugPrint('Status: ${e.response?.statusCode}');
        debugPrint('Body: ${e.response?.data}');
      } catch (e) {
        // Errore non previsto
        debugPrint('❌ Generic error in _initAndRoute: $e');
      }

      // In ogni caso, se qualcosa va storto, pulisci il token
      await prefs.remove('access_token');
      await prefs.remove('remember_me');
    }

    return LoginPage();
  }


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
}