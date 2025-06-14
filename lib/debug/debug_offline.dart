import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:openpark/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login.dart';
import '../driver/driver_layout.dart';
import '../controller/controller_layout.dart';
import '../admin/admin_layout.dart';
import '../main.dart';
import 'package:timezone/timezone.dart' as tz;
import '../driver/card_payment.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class DebugRoleSelectorOffline extends StatelessWidget {
  const DebugRoleSelectorOffline({super.key});

  void _navigateToRoleOffline(BuildContext context, String role) {
    Widget destination;
    globalRole = role; // Set the global role for the app

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
    final context = navigatorKey.currentContext;
    final now = DateTime.now();

    final fakeEnd = now.add(const Duration(seconds: 60));
    final expiringAt = fakeEnd.subtract(const Duration(seconds: 5));
    final expiredAt = fakeEnd.add(const Duration(seconds: 5));

    try {
      await cancelTicketNotifications(id: 99999);

      final androidDetails = AndroidNotificationDetails(
        'ticket_channel',
        'Ticket Notifications',
        channelDescription: 'Notify when ticket is about to expire or just expired',
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
      );
      final notificationDetails = NotificationDetails(android: androidDetails);

      await safeZonedSchedule(
        id: 99999,
        title: '⏰ Ticket expiring soon!',
        body: 'This ticket will expire in 5 seconds.',
        when: tz.TZDateTime.from(expiringAt, tz.local),
        details: notificationDetails,
        payload: 'open_ticket',
      );

      await safeZonedSchedule(
        id: 100999,
        title: '⚠️ Ticket expired!',
        body: 'Your parking time ended 5 seconds ago.',
        when: tz.TZDateTime.from(expiredAt, tz.local),
        details: notificationDetails,
        payload: 'open_ticket',
      );

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Notifications scheduled with fallback if needed")),
          );
      }

    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Scheduling error: $e")),
        );
      }
    }
  }

  void _testAllNotifications() {
  _simulateExpiringTicketNotification();
  testImmediateAndScheduledNotifications();
  _scheduleWithAlarmManager();
  }

  void _scheduleWithAlarmManager() async {
    final success = await AndroidAlarmManager.oneShot(
      const Duration(seconds: 30), // 🔁 cambia se vuoi altro tempo
      123,                         // ID unico (può essere qualsiasi numero)
      showAlarmNotification,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "✅ Alarm scheduled in 30s" : "❌ Failed to schedule alarm")),
      );
    }
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
              const Text(
                "Select a role to test:",
                style: TextStyle(fontSize: 18),
              ),
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
                onPressed: _testAllNotifications,
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
                          // Simula fine ticket tra 30 secondi
                          final fakeEnd = DateTime.now().add(Duration(seconds: 30));
                          await cancelTicketNotifications(id: 88888);
                          await scheduleTicketNotifications(id: 88888, end: fakeEnd);

                          final contextInside = navigatorKey.currentContext;
                          if (contextInside != null) {
                            ScaffoldMessenger.of(contextInside).showSnackBar(
                              const SnackBar(content: Text("✅ Simulated RFID payment with notification")),
                            );
                          }
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

