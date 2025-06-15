import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'login.dart';
import 'controller/issue_fine.dart';
import 'installer/totem_otp.dart';
import 'utils/totem_config_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'notifications.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Rome'));

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

  // ✅ Inizializzazione notifiche (tutorial-style)
  await initNotification();

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
