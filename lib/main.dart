// main.dart
import 'package:flutter/material.dart';
import 'login.dart';
import 'db/db_zones.dart';
import 'controller/issue_fine.dart';
import 'config.dart';
import 'debug/debug_role_selector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load parking zones from CSV before launching app
  await ZoneDB.loadZones();

  runApp(ParkingApp());
}

class ParkingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
      },
      home: debugMode ? const DebugRoleSelector() : LoginPage(),
    );
  }
}
