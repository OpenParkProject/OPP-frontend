import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login.dart';
import '../driver/driver_layout.dart';
import '../controller/controller_layout.dart';
import '../admin/admin_layout.dart';
import '../driver/card_payment.dart';
import '../notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DebugRoleSelectorOffline extends StatelessWidget {
  const DebugRoleSelectorOffline({super.key});

  void _navigateToRoleOffline(BuildContext context, String role) {
    Widget destination;

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
      case 'installer':
        destination = LoginPage();
        break;
      default:
        destination = LoginPage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _simulateExpiringTicketNotification() async {
    final rome = tz.getLocation('Europe/Rome');
    final now = tz.TZDateTime.now(rome);
    final scheduled = now.add(const Duration(seconds: 30));

    // Notifica immediata
    await flutterLocalNotificationsPlugin.show(
      90001,
      '📢 Immediate Notification',
      'This is shown instantly.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ticket_channel',
          'Ticket Notifications',
          channelDescription: 'Notify when ticket is about to expire or just expired',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'open_now',
    );

    // Notifica tra 30 secondi
    await scheduleNotification(
      id: 90002,
      title: '🔔 Scheduled Notification',
      body: 'This was scheduled 30 seconds ago.',
      scheduledDate: scheduled,
    );

    debugPrint('[✓] Sent immediate notification at $now');
    debugPrint('[✓] Scheduled notification for $scheduled');
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
                onPressed: () => _navigateToRoleOffline(context, 'driver'),
                child: const Text('Driver Interface'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _navigateToRoleOffline(context, 'controller'),
                child: const Text('Controller Interface'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _navigateToRoleOffline(context, 'admin'),
                child: const Text('Admin Interface'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _navigateToRoleOffline(context, 'installer'),
                child: const Text('Installer Interface'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _simulateExpiringTicketNotification,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('🔔 Simulate Expiring Ticket'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool("totem_mode", true);
                  await prefs.setBool("rfid", true);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardPaymentPage(
                        onConfirmed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Test payment successful")),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
                child: const Text('🧪 Test RFID Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
