import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/client.dart';

class OTPPage extends StatefulWidget {
  const OTPPage({super.key});

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  String? otp;
  DateTime? validUntil;

  @override
  void initState() {
    super.initState();
    _loadOtpFromStorage();
  }

  Future<void> _loadOtpFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedOtp = prefs.getString('otp');
    final storedValidUntil = prefs.getString('valid_until');

    if (storedOtp != null && storedValidUntil != null) {
      final parsedDate = DateTime.tryParse(storedValidUntil);
      if (parsedDate != null && parsedDate.isAfter(DateTime.now())) {
        setState(() {
          otp = storedOtp;
          validUntil = parsedDate;
        });
      } else {
        // Scaduto
        await prefs.remove('otp');
        await prefs.remove('valid_until');
      }
    }
  }

  Future<void> _generateOtp() async {
    try {
      await DioClient().setAuthToken();
      final response = await DioClient().dio.get('/otp');
      final newOtp = response.data;

      if (newOtp['otp'] != null && newOtp['valid_until'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('otp', newOtp['otp']);
        await prefs.setString('valid_until', newOtp['valid_until']);

        setState(() {
          otp = newOtp['otp'];
          validUntil = DateTime.tryParse(newOtp['valid_until']);
        });
      } else {
        throw Exception("Invalid OTP format from server");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate OTP: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = validUntil != null && validUntil!.isBefore(DateTime.now());

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _generateOtp,
          icon: const Icon(Icons.add),
          label: const Text("Generate New OTP"),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: otp == null || validUntil == null
              ? const Center(child: Text("No active OTP"))
              : ListTile(
                  title: Text("OTP: $otp"),
                  subtitle: Text(
                    "Valid until: ${DateFormat.yMd().add_Hm().format(validUntil!)}",
                  ),
                  trailing: Icon(
                    isExpired ? Icons.warning : Icons.check_circle,
                    color: isExpired ? Colors.red : Colors.green,
                  ),
                ),
        ),
      ],
    );
  }
}
