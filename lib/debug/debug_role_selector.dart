import 'package:flutter/material.dart';
import 'package:openpark/config.dart';

import '../controller/layout.dart';
import '../driver/layout.dart';
import '../login.dart';
// import '../admin/admin_dashboard.dart';

class DebugRoleSelector extends StatelessWidget {
  const DebugRoleSelector({super.key});

  void _navigateToRole(BuildContext context, String role) {
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
        // destination = AdminLayout(username: 'debug_admin');
        destination = ControllerLayout(username: 'debug_admin');
        break;
      default:
        destination = LoginPage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
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
                onPressed: () => _navigateToRole(context, 'admin'),
                child: const Text('Admin Interface'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
