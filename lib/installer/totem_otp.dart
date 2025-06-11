import 'package:flutter/material.dart';
import 'totem_install.dart';
import 'package:dio/dio.dart';
import '../API/client.dart';

class TotemOtpPage extends StatefulWidget {
  const TotemOtpPage({super.key});

  @override
  State<TotemOtpPage> createState() => _TotemOtpPageState();
}

class _TotemOtpPageState extends State<TotemOtpPage> {
  final TextEditingController _otpController = TextEditingController();

  void _submitOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the OTP.")),
      );
      return;
    }

    try {
      final dio = DioClient().dio;

      final response = await dio.post(
        '/otp/validate',
        data: {'otp': otp},
      );

      // Se la validazione va a buon fine, procedi
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TotemInstallPage(
            enabledZones: const [], // <-- puoi fare una nuova GET se servono zone dopo
            otp: otp,
          ),
        ),
      );
    } catch (e) {
      String errorMessage = "OTP verification failed.";
      if (e is DioError && e.response != null) {
        errorMessage += " (${e.response?.statusCode})";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
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
