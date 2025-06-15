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
import 'package:flutter/foundation.dart'; // necessario per kIsWeb

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();

  bool showSignUp = false;
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

  void _triggerTotemMode() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || kIsWeb) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TotemOtpPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Totem setup is only available on desktop or web.")),
      );
    }
  }

  void _loadTotemInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isTotem') == true) {
      setState(() {
        totemInfo = {
          'zoneName': prefs.getString('zone_name') ?? 'Unknown zone',
          'rfid': prefs.getBool('rfid_enabled') ?? 'Unknown'
        };
      });
    }
  }

  void _showMessage(String text, {Color background = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: background,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _handleAuth() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage("Please enter both username and password");
      return;
    }

    final dio = DioClient().dio;

    try {
      final response = await dio.post('/login', data: {
        'username': username,
        'password': password,
      });
      await _handleLoginSuccess(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        setState(() => showSignUp = true); // 🔁 mostra il form
        _showMessage("User not found. Please complete the registration.");
      } else {
        _handleError(e, context: "Login");
      }
    }

  }

  void _handleRegistration() async {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if ([name, surname, email, username, password, confirm].any((e) => e.isEmpty)) {
      _showMessage("Please fill in all fields");
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage("Invalid email format");
      return;
    }

    if (password != confirm) {
      _showMessage("Passwords do not match");
      return;
    }

    try {
      final dio = DioClient().dio;

      await dio.post('/register', data: {
        "name": name,
        "surname": surname,
        "username": username,
        "email": email,
        "password": password,
        "role": "driver",
      });

      _showMessage("Registration successful. You can now sign in.");
      setState(() => showSignUp = false);
    } catch (e) {
      _handleError(e, context: "Registration");
    }
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> data) async {
    final token = data['access_token'];
    final user = data['user'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await DioClient().setAuthToken();

    globalRole = user['role'];

    if (user['role'] == "superuser") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SuperuserLayout(username: user['username'])),
      );
    } else if (user['role'] == "admin") {
      final zoneResp = await DioClient().dio.get('/zones/me');
      final zoneIds = zoneResp.data.map<String>((z) => z['id'].toString()).toList();
      final zoneNames = zoneResp.data.map<String>((z) => z['name'].toString()).toList();
      await prefs.setStringList('zone_ids', zoneIds);
      await prefs.setStringList('zone_names', zoneNames);
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => AdminLayout(username: user['username']),
      ));
    } else if (user['role'] == "controller") {
      final zoneResp = await DioClient().dio.get('/zones/me');
      final zoneIds = zoneResp.data.map<String>((z) => z['id'].toString()).toList();
      final zoneNames = zoneResp.data.map<String>((z) => z['name'].toString()).toList();
      await prefs.setStringList('zone_ids', zoneIds);
      await prefs.setStringList('zone_names', zoneNames);
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => ControllerLayout(username: user['username']),
      ));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => MainUserHomePage(username: user['username']),
      ));
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
          if (debugMode)
            Positioned(
              top: 40,
              left: 16,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DebugModeSelector()));
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
                            GestureDetector(
                              onTap: _triggerTotemMode,
                              child: Material(
                                color: Colors.transparent,
                                child: Column(
                                  children: [
                                    const Text(
                                      'OpenPark',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 50,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.blueAccent,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (totemInfo != null && totemInfo!['zoneName'] != null) ...[
                                      Text(
                                        "📍 ${totemInfo!['zoneName']} Zone",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.red, // come il pin
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 160,
                                        height: 2,
                                        color: Colors.red, // la riga è rossa sotto zona
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 100,
                                        height: 2,
                                        color: Colors.blueAccent, // riga blu sotto OpenPark
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
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
                              icon: Icon(Icons.directions_car),
                              label: Text("Pay with plate (without login)"),
                            ),

                            const SizedBox(height: 4),
                            if (totemInfo != null && totemInfo!['zoneName'] != null)
                              Text(
                                "📍 ${totemInfo!['zoneName']} Zone",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: "Username",
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
                            if (showSignUp) ...[
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
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: showSignUp ? _handleRegistration : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(showSignUp ? "Create Account" : "Sign In"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ForgotPasswordPage()),
                                );
                              },
                              child: Text("Forgot Password?"),
                            ),
                          ]
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
