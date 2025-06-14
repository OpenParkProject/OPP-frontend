import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:openpark/debug/debug_mode_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/admin_layout.dart';
import 'config.dart';
import 'controller/controller_layout.dart';
import 'driver/driver_layout.dart';
import 'driver/zone_selection.dart';
import 'API/client.dart';
import 'installer/totem_otp.dart';
import 'dart:io';
import 'forgot_pw.dart';
import '/superuser/superuser_layout.dart';



class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isSignIn = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();

  void _showMessage(String text, {Color background = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: background,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Map<String, dynamic>? totemInfo;

  @override
  void initState() {
    super.initState();
    _loadTotemInfo();
    _debugPrintSharedPrefs();
  }

  void _debugPrintSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    debugPrint('------ SharedPreferences ------');
    for (var key in allKeys) {
      final value = prefs.get(key);
      debugPrint('$key: $value');
    }
    debugPrint('-------------------------------');
  }

  void _loadTotemInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isTotem') == true) {
      setState(() {
        totemInfo = {
          'zoneName': prefs.getString('zone_name') ?? 'Unknown zone',
        };
      });
    }
  }

  void _handleAuth() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final dio = DioClient().dio;

    if (isSignIn) {
      try {
        final response = await dio.post(
          '/login',
          data: {'username': username, 'password': password},
        );

        final user = response.data['user'];
        final token = response.data['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);

        await DioClient().setAuthToken();

        //_showMessage("Login successful: Welcome, ${user['username']}!");

        String role = user['role'] ?? '';
        globalRole = role; // Store globally for later use

        if (role == "superuser") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SuperuserLayout(username: user['username'])),
          );
        } else if (role == "admin") {
          try {
            final zonesResponse = await dio.get('/zones/me');
            final zoneList = zonesResponse.data as List<dynamic>;
            final zoneIds = zoneList.map((z) => z['id'].toString()).toList();
            final zoneNames = zoneList.map((z) => z['name'].toString()).toList();

            await prefs.setStringList('zone_ids', zoneIds);
            await prefs.setStringList('zone_names', zoneNames);
          } catch (e) {
            //_showMessage("Failed to fetch zones for admin");
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminLayout(username: user['username'])),
          );
        } else if (role == "controller") {
          try {
            final zonesResponse = await dio.get('/zones/me');
            final prefs = await SharedPreferences.getInstance();

            final zoneList = zonesResponse.data as List<dynamic>;
            final zoneIds = zoneList.map((z) => z['id'].toString()).toList();
            final zoneNames = zoneList.map((z) => z['name'].toString()).toList();

            await prefs.setStringList('zone_ids', zoneIds);
            await prefs.setStringList('zone_names', zoneNames);
          } catch (e) {
            //_showMessage("Failed to fetch zones for controller");
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ControllerLayout(username: user['username'])),
          );
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainUserHomePage(username: user['username'])));
        }
      } catch (e) {
        _handleError(e, context: "Login");
      }
    } else {
      final confirm = _confirmPasswordController.text.trim();
      final name = _nameController.text.trim();
      final surname = _surnameController.text.trim();
      final email = _emailController.text.trim();

      if ([
        name,
        surname,
        username,
        email,
        password,
        confirm,
      ].any((e) => e.isEmpty)) {
        _showMessage("Please fill in all fields");
        return;
      }

      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailRegex.hasMatch(email)) {
        _showMessage("Please enter a valid email address");
        return;
      }

      if (password != confirm) {
        _showMessage("Passwords do not match");
        return;
      }

      try {
        await dio.post(
          '/register',
          data: {
            "name": name,
            "surname": surname,
            "username": username,
            "email": email,
            "password": password,
            "role": "driver",
          },
        );

        _showMessage("Account created, you can now sign in");
        setState(() {
          isSignIn = true;
        });
      } catch (e) {
        _handleError(e, context: "Registration");
      }
    }
  }

  void _handleError(Object e, {required String context}) {
    String errorMsg = "$context failed";
    if (e is DioException) {
      final errorData = e.response?.data;
      if (errorData is Map<String, dynamic>) {
        if (errorData.containsKey('detail')) {
          errorMsg = "$context failed: ${errorData['detail']}";
        } else if (errorData.containsKey('error')) {
          errorMsg = "$context failed: ${errorData['error']}";
        } else {
          errorMsg = "$context failed: ${errorData.values.join(', ')}";
        }
      }
    } else {
      errorMsg = "$context failed: ${e.toString()}";
    }
    _showMessage(errorMsg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          
          // Debug Mode Button - positioned in top left corner
          if (debugMode) // Only show in debug mode
            Positioned(
              top: 40,
              left: 16,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => DebugModeSelector())
                  );
                },
                icon: Icon(Icons.bug_report),
                label: Text("Debug"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          
    Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth;

            return Container(
              
              width: width < 600 ? width * 0.9 : width * 2 / 3,
              child: Card(
                color: Colors.white.withAlpha((0.9 * 255).round()),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 9.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          Text(
                            'OpenPark',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.w800,
                              color: Colors.blueAccent,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Container(
                            height: 3,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                  SizedBox(height: 15),
                      SizedBox(height: 10),
                      if (totemInfo != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.memory, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Running in Totem mode (${totemInfo!['zoneName']})',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final dio = DioClient().dio;

                            try {
                              final loginResp = await dio.post('/login', data: {
                                'username': 'guest',
                                'password': 'guest123',
                              });
                              final token = loginResp.data['access_token'];
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('access_token', token);
                              DioClient().dio.options.headers['Authorization'] = 'Bearer $token';
                            } on DioException catch (e) {
                              if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
                                await dio.post('/register', data: {
                                  "name": "Guest",
                                  "surname": "User",
                                  "username": "guest",
                                  "email": "guest@openpark.app",
                                  "password": "guest123",
                                  "role": "driver",
                                });
                                final loginResp = await dio.post('/login', data: {
                                  'username': 'guest',
                                  'password': 'guest123',
                                });
                                final token = loginResp.data['access_token'];
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('access_token', token);
                                DioClient().dio.options.headers['Authorization'] = 'Bearer $token';
                              } else {
                                throw Exception("Guest login error: ${e.message}");
                              }
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ParkingZoneSelectionPage(fromGuest: true),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Guest login failed: $e")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 68),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "Pay with plate (without login/registration)",
                                textAlign: TextAlign.center,
                              )
                            ),
                          ],
                        ),
                      ),
                     SizedBox(height: 24),
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(12),
                        isSelected: [!isSignIn, isSignIn],
                        onPressed: (int index) {
                          setState(() {
                            isSignIn = index == 1;
                          });
                        },
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text("Sign Up"),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text("Sign In"),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller:
                            isSignIn ? _usernameController : _emailController,
                        decoration: InputDecoration(
                          labelText: isSignIn ? "Username" : "Email",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (!isSignIn) ...[
                        SizedBox(height: 10),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _surnameController,
                          decoration: InputDecoration(
                            labelText: "Surname",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: "Username",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _handleAuth,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(isSignIn ? "Sign In" : "Create Account"),
                      ),
                      if (isSignIn)
                        SizedBox(height: 3),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ForgotPasswordPage()),
                            );
                          },
                          onLongPress: () {
                            if (Platform.isWindows || Platform.isLinux) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TotemOtpPage()));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Totem setup is only available on desktop devices.")),
                              );
                            }
                          },
                          child: Text("Forgot Password?"),
                        ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  ],
),
);
}
}