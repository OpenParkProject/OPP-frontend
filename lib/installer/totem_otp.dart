import 'package:flutter/material.dart';
import 'totem_install.dart';
import 'package:dio/dio.dart';
import '../API/client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../login.dart';

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

    if (otp == disableTotemOtp) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isTotem', false);
      await prefs.remove('zone_id');
      await prefs.remove('zone_name');
      await prefs.remove('latitude');
      await prefs.remove('longitude');
      await prefs.remove('rfid_enabled');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Totem mode disabled. Restarting...")),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
            (_) => false,
          );
        });
      }
      return;
    }
    if (otp == totemTestOtpRfidOn || otp == totemTestOtpRfidOff) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isTotem', true);
      await prefs.setInt('zone_id', 1); // Dummy ID
      await prefs.setString('zone_name', 'Test Zone');
      await prefs.setDouble('latitude', 45.0703); // Example coordinates
      await prefs.setDouble('longitude', 7.6869);
      await prefs.setBool('rfid_enabled', otp == totemTestOtpRfidOn);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              otp == totemTestOtpRfidOn
                  ? "Totem test mode activated (RFID enabled)"
                  : "Totem test mode activated (RFID disabled)",
            ),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
            (_) => false,
          );
        });
      }
      return;
    }

    setState(() => _loading = true);

    try {
      final dio = DioClient().dio;

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
