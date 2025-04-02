import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:plate_ocr/payment.dart';
import 'theme_notifier.dart';
import 'package:opp_api_client/opp_api_client.dart';
import 'package:dio/dio.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _useremailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;

  // Istantiate Dio 
  final API = OppApiClient(dio: Dio(BaseOptions(baseUrl: "http://10.0.2.2:10020/api/v1/")));


  Future<void> _registerUser() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The passwords do not match.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final UserApi = API.getUserApi();

    User user = User((b) => b
      ..name = "Simone"
      ..surname = "Tollardo"
      ..email = "simonetollardo@gmail.com"
      ..password = "password"
      ..role = UserRoleEnum.driver
      ..id = 1
    );

    UserApi.addUser(user: user).then((value) => print(value.statusCode));

  }

  void _showRegistrationSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registration Success'),
          content: const Text('Your account has been successfully registered!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ParkingPaymentPage(),
                  ),
                );
              },
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create an account'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _useremailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Username'),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _confirmController,
                        decoration: const InputDecoration(labelText: 'Confirm your password'),
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _registerUser,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}