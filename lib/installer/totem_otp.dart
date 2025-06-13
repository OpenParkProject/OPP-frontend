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
  bool _loading = false;

  void _submitOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the OTP.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final dio = DioClient().dio;

      // Unica richiesta: ottiene zone associate all'OTP
      final zonesRes = await dio.get('/zones/me/$otp');
      final List<dynamic> zones = zonesRes.data;

      if (zones.isEmpty) {
        throw Exception("No zones available for this OTP.");
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TotemInstallPage(
              enabledZones: zones.cast<Map<String, dynamic>>(),
              otp: otp,
            ),
          ),
        );
      }
    } catch (e) {
      String msg = "OTP not valid or network error.";
      if (e is DioError && e.response != null && e.response?.statusCode == 404) {
        msg = "OTP not valid.";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
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
                      onPressed: _loading ? null : _submitOtp,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("OK", style: TextStyle(fontSize: 16)),
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
