import 'package:flutter/material.dart';
import 'controller_home.dart';
import 'main_user_home.dart';
import 'parking_zone_selection.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final Dio _dio = Dio(BaseOptions(baseUrl: "http://openpark.com/api/v1"));

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
    

    if (isSignIn) {
      try {
        final response = await _dio.post('/login', data: {
          'username': username,
          'password': password,
        });

        final user = response.data['user'];
        final role = user['username'] == 'controller' ? 'controller' : 'driver';
        final token = response.data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        print("Token saved: $token");

        _showMessage("Login successful: Welcome, ${user['username']}!");
        // To retrieve the token in every page or file:
        // final prefs = await SharedPreferences.getInstance();
        // final token = prefs.getString('access_token');
        // print("Token recuperato: $token");


        if (role == 'controller') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ControllerHome()));
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainUserHomePage(username: user['username']),
            ),
          );
        }
      } catch (e) {
      if (e is DioException) {
        print("Error: ${e.response?.data}");
        final errorData = e.response?.data;
        String errorMsg;

        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('detail')) {
            errorMsg = errorData['detail'];
          } else if (errorData.containsKey('error')) {
            errorMsg = errorData['error'];
          } else {
            errorMsg = errorData.values.join(", ");
          }
        } else {
          errorMsg = 'Unknown error';
        }

        _showMessage("Login failed: $errorMsg");
      } else {
        _showMessage("Login failed: ${e.toString()}");
      }
    }

    } else {
      final confirm = _confirmPasswordController.text.trim();
      final name = _nameController.text.trim();
      final surname = _surnameController.text.trim();
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();

      if ([name, surname, username, email, password, confirm].any((e) => e.isEmpty)) {
        _showMessage("Please fill in all fields");
        return;
      }

      if (password != confirm) {
        _showMessage("Passwords do not match");
        return;
      }

      try {
        await _dio.post(
          '/register',
          data: {
            "name": name,
            "surname": surname,
            "username": username,
            "email": email,
            "password": password,
            "role": "driver"
          },
          options: Options(
            headers: {
              "Content-Type": "application/json",
            },
          ),
        );

        _showMessage("Account created, you can now sign in");
        setState(() {
          isSignIn = true;
        });
      } catch (e) {
        if (e is DioException) {
          print("Error: ${e.response?.data}");
          final errorData = e.response?.data;
          String errorMsg;

          if (errorData is Map<String, dynamic>) {
            if (errorData.containsKey('detail')) {
              errorMsg = errorData['detail'];
            } else if (errorData.containsKey('error')) {
              errorMsg = errorData['error'];
            } else {
              errorMsg = errorData.values.join(", ");
            }
          } else {
            errorMsg = 'Unknown error';
          }

          _showMessage("Registration failed: $errorMsg");
        } else {
          _showMessage("Registration failed: ${e.toString()}");
        }
      }
    }
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
          Container(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 170),
              child: Card(
                color: Colors.white.withOpacity(0.9),
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 20),
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(12),
                        isSelected: [!isSignIn, isSignIn],
                        onPressed: (int index) {
                          setState(() {
                            isSignIn = index == 1;
                          });
                        },
                        children: [
                          Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Sign Up")),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Sign In")),
                        ],
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: isSignIn ? _usernameController : _emailController,
                        decoration: InputDecoration(labelText: isSignIn ? "Username" : "Email", border: OutlineInputBorder()),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                      ),
                      if (!isSignIn) ...[
                        SizedBox(height: 10),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder()),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder()),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _surnameController,
                          decoration: InputDecoration(labelText: "Surname", border: OutlineInputBorder()),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder()),
                        ),
                      ],
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _handleAuth,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(isSignIn ? "Sign In" : "Create Account"),
                      ),
                      if (isSignIn)
                        TextButton(
                          onPressed: () {},
                          child: Text("Forgot Password?"),
                        ),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ParkingZoneSelectionPage()));
                        },
                        icon: Icon(Icons.local_parking_outlined),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        label: Text("Pay with plate (without login/registration)"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}