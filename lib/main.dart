import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'login.dart';
import 'controller/issue_fine.dart';
import 'installer/totem_otp.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notifications.dart';
import 'API/client.dart';
import 'superuser/superuser_layout.dart';
import 'admin/admin_layout.dart';
import 'controller/controller_layout.dart';
import 'driver/driver_layout.dart';
import 'utils/totem_inactivity_handler.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Rome'));

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

  await initNotification();

  final prefs = await SharedPreferences.getInstance();
  final bool isTotem = prefs.getBool('isTotem') == true;
  final bool configured = prefs.getInt('zone_id') != null;

  if (isTotem) {
    await clearAllPrefsExceptTotem();
  }

  Widget initialWidget;

  if (isTotem) {
    initialWidget = configured ? LoginPage() : const TotemOtpPage();
  } else {
    final token = prefs.getString('access_token');

    if (token != null) {
      DioClient().dio.options.headers['Authorization'] = 'Bearer $token';

      try {
        final userResp = await DioClient().dio.get('/users/me');
        final role = userResp.data['role'];
        final username = userResp.data['username'];

        if (role == 'superuser') {
          initialWidget = SuperuserLayout(username: username);
        } else if (role == 'admin') {
          final zoneResp = await DioClient().dio.get('/zones/me');
          final zoneIds = zoneResp.data.map<String>((z) => z['id'].toString()).toList();
          final zoneNames = zoneResp.data.map<String>((z) => z['name'].toString()).toList();
          await prefs.setStringList('zone_ids', zoneIds);
          await prefs.setStringList('zone_names', zoneNames);
          initialWidget = AdminLayout(username: username);
        } else if (role == 'controller') {
          final zoneResp = await DioClient().dio.get('/zones/me');
          final zoneIds = zoneResp.data.map<String>((z) => z['id'].toString()).toList();
          final zoneNames = zoneResp.data.map<String>((z) => z['name'].toString()).toList();
          await prefs.setStringList('zone_ids', zoneIds);
          await prefs.setStringList('zone_names', zoneNames);
          initialWidget = ControllerLayout(username: username);
        } else {
          initialWidget = MainUserHomePage(username: username);
        }
      } catch (e) {
        debugPrint('⚠️ Token validation error: $e');
        await prefs.remove('access_token');
        initialWidget = LoginPage();
      }
    } else {
      initialWidget = LoginPage();
    }
  }

  runApp(
    GlobalInactivityHandler(
      child: ParkingApp(initialWidget: initialWidget),
    ),
  );
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
