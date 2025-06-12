import 'package:flutter/material.dart';
import 'totem_install.dart';

class TotemOtpPage extends StatefulWidget {
  const TotemOtpPage({super.key});

  @override
  State<TotemOtpPage> createState() => _TotemOtpPageState();
}

class _TotemOtpPageState extends State<TotemOtpPage> {
  final TextEditingController _otpController = TextEditingController();

  void _submitOtp() {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the OTP.")),
      );
      return;
    }

    // Bypassa ogni verifica e passa direttamente alla pagina di installazione
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TotemInstallPage(
          enabledZones: const [],  // potrai fare una GET nella pagina successiva
          otp: otp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Totem Installation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Enter the OTP provided by the admin to begin installation.",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _otpController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: "OTP",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitOtp,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text("OK", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
