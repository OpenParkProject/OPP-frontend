import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:openpark/installer/install_totem.dart';

import '../login.dart';
import '../driver/layout.dart';
import '../controller/layout.dart';
import '../admin/layout.dart';
import '../main.dart';

class DebugRoleSelector extends StatelessWidget {
  const DebugRoleSelector({super.key});

  void _navigateToRole(BuildContext context, String role) {
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
        destination = InstallTotemPage(username: 'debug_installer');
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
    try {
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '⏰ Ticket expiring soon!',
        'Your parking will expire in 1 minute.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ticket_channel',
            'Ticket Notifications',
            channelDescription: 'Notify when ticket is about to expire',
            importance: Importance.max,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
            ticker: 'Ticket Alert',
            playSound: true,
            enableVibration: true,
            category: AndroidNotificationCategory.reminder,
            styleInformation: BigTextStyleInformation('Your parking will expire in 1 minute. Extend your ticket now to avoid a fine.'),
          ),
        ),
        payload: 'open_ticket',
      );
      debugPrint('[✓] Realistic ticket notification sent!');
    } catch (e) {
      debugPrint('[✗] Failed to send notification: $e');
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
                onPressed: () => _navigateToRole(context, 'installer'),
                child: const Text('Installler Interface'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _navigateToRole(context, 'admin'),
                child: const Text('Admin Interface'),
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