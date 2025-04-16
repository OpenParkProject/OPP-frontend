import 'package:flutter/material.dart';
import '../db/db_users.dart';
import 'controller_home.dart';
import 'main_user_home.dart';
import 'parking_zone_selection.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isSignIn = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _handleAuth() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final db = MockDB();

    if (isSignIn) {
      if (email == "controller") {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ControllerHome()));
        return;
      }

      if (db.loginUser(email, password)) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => MainUserHomePage(username: email)));
      } else {
        _showMessage("Invalid credentials");
      }
    } else {
      final confirm = _confirmPasswordController.text.trim();
      if (password != confirm) {
        _showMessage("Passwords do not match");
        return;
      }
      if (db.registerUser(email, password)) {
        _showMessage("Account created, you can now sign in");
        setState(() {
          isSignIn = true;
        });
      } else {
        _showMessage("User already exists");
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
              padding: const EdgeInsets.only(top: 170), // This lines moves the block down to show the logo on the background
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
                        controller: _emailController,
                        decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
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
