import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/client.dart';
import '../login.dart';
import '../driver/driver_layout.dart';
import '../controller/controller_layout.dart';
import '../admin/admin_layout.dart';
import '../notifications.dart';

class DebugRoleSelectorOnline extends StatelessWidget {
  const DebugRoleSelectorOnline({super.key});

  Future<void> _navigateToRole(BuildContext context, String role) async {
    Widget destination;

    try {
      await _ensureUserExists(role);

      switch (role) {
        case 'driver':
          destination = const MainUserHomePage(username: 'debug_driver');
          break;
        case 'controller':
          destination = const ControllerLayout(username: 'debug_controller');
          break;
        case 'admin':
          destination = AdminLayout(username: 'debug_admin');
          break;
        default:
          destination = LoginPage();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _ensureUserExists(String role) async {
    final dio = DioClient().dio;

    String username = 'debug_$role';
    String password = 'debug_$role';
    String email = 'debug_${role}@email.com';

    try {
      final loginResponse = await dio.post('/login', data: {
        "username": username,
        "password": password,
      });

      final token = loginResponse.data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await DioClient().setAuthToken();
    } catch (_) {
      await dio.post('/register', data: {
        "name": username,
        "surname": username,
        "username": username,
        "email": email,
        "password": password,
        "role": role,
      });

      final loginResponse = await dio.post('/login', data: {
        "username": username,
        "password": password,
      });

      final token = loginResponse.data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await DioClient().setAuthToken();
    }
  }

  void _simulateExpiringTicketNotification() async {
    final now = DateTime.now();
    final scheduled = now.add(const Duration(seconds: 30));

    await scheduleNotification(
      id: 90001,
      title: '🔔 Test Notification',
      body: 'This was scheduled 30 seconds ago.',
      scheduledDate: scheduled,
    );

    debugPrint('[✓] Scheduled test notification for $scheduled');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Mode – Select Role')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select a role to test:", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _navigateToRole(context, 'driver'),
                child: const Text('Driver Interface'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _navigateToRole(context, 'controller'),
                child: const Text('Controller Interface'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _navigateToRole(context, 'admin'),
                child: const Text('Admin Interface'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _navigateToRole(context, 'installer'),
                child: const Text('Installer Interface'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _simulateExpiringTicketNotification,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('🔔 Simulate Expiring Ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
