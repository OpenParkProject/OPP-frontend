import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:openpark/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/client.dart';

import '../login.dart';
import '../driver/driver_layout.dart';
import '../controller/controller_layout.dart';
import '../admin/admin_layout.dart';
import '../main.dart';

class DebugRoleSelector extends StatelessWidget {
  const DebugRoleSelector({super.key});

  Future<void> _navigateToRole(BuildContext context, String role) async {
    Widget destination;
    globalRole = role; // Set the global role for the app
    
    try {

      // Else, handle other roles (driver, controller, admin)

      // Create or ensure the user exists for the role
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

      // Navigate to the destination page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } catch (e) {
      // Handle errors during user creation/verification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _ensureUserExists(String role) async {
    // Get the dio instance from the singleton
    final dio = DioClient().dio;
    
    String username = 'debug_$role';
    String password = 'debug_$role';
    String email = 'debug_${role}@email.com';
    
    try {
      // First try to log in as this user
      final loginResponse = await dio.post('/login', 
        data: {
          "username": username,
          "password": password,
        }
      );
      
      // Check if login was successful
      final user = loginResponse.data['user'];
      final token = loginResponse.data['access_token'];
      
      // Store the token in SharedPreferences (matching login.dart)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      
      // Now set the auth token
      await DioClient().setAuthToken();
      debugPrint('User $username already exists, logged in successfully.');
    } catch (e) {
      debugPrint('User $username does not exist or login failed, trying to register...');
      
      try {
        await dio.post(
          '/register',
          data: {
            "name": username,
            "surname": username,
            "username": username,
            "email": email,
            "password": password,
            "role": role,
          },
        );
        
        // After registering, log in to get the token
        final loginResponse = await dio.post('/login', 
          data: {
            "username": username,
            "password": password,
          }
        );
        
        // Match the same token extraction as login.dart
        final user = loginResponse.data['user'];
        final token = loginResponse.data['access_token'];
        
        // Store the token in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        
        // Now set the auth token
        await DioClient().setAuthToken();
        debugPrint('User $username registered and logged in successfully.');
      } catch (registerError) {
        debugPrint('REGISTRATION ERROR: $registerError');
        
        if (registerError is DioException) {
          final DioException dioError = registerError;
          if (dioError.response != null) {
            debugPrint('Status: ${dioError.response?.statusCode}');
            debugPrint('Response data: ${dioError.response?.data}');
          }
        }
        
        throw Exception('Failed to register user: $registerError');
      }
    }
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