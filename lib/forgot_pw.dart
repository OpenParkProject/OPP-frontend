import 'package:flutter/material.dart';
import 'package:openpark/config.dart';              // totemSecret
import 'package:openpark/installer/totem_otp.dart'; // TotemOtpPage


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _sending = false;

  void _submitEmail() async {
    final email = _emailController.text.trim();

    if (email == totemSecret) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TotemOtpPage()),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      _showMessage("Please enter a valid email address.");
      return;
    }

    setState(() => _sending = true);

    await Future.delayed(Duration(seconds: 1)); // simulate loading

    _showMessage("If the email is correct, you will receive an email to reset your password.");

    await Future.delayed(Duration(seconds: 2));
    if (context.mounted) {
      Navigator.pop(context); // go back to login
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Recover Password")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "Enter the email you used to register in order to recover your credentials.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sending ? null : _submitEmail,
              child: _sending
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Send Recovery Email"),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }
}
