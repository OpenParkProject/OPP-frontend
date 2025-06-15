import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../API/client.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _loadOtpFromPrefs();
  }

  Future<void> _loadOtpFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedOtp = prefs.getString('otp');
    final storedUntil = prefs.getString('valid_until');

    if (storedOtp != null && storedUntil != null) {
      final parsed = DateTime.tryParse(storedUntil);
      if (parsed != null && parsed.isAfter(DateTime.now())) {
        setState(() {
          otp = storedOtp;
          validUntil = parsed;
        });
      }
    }
  }

  Future<void> _generateOtp() async {
    try {
      await DioClient().setAuthToken();

      final zonesResponse = await DioClient().dio.get('/zones/me');
      final zonesData = zonesResponse.data;
      debugPrint('zonesData: ${zonesData.toString()}');

      if (zonesData == null || (zonesData is List && zonesData.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You have no zones assigned. Please create or be assigned to at least one zone before generating an OTP."),
          ),
        );
        return;
      }

      final response = await DioClient().dio.get('/otp');
      final newOtp = response.data;
      debugPrint('newOtp: $newOtp');

      if (newOtp is Map<String, dynamic> &&
          newOtp['otp'] is String &&
          newOtp['valid_until'] != null) {
        setState(() {
          otp = newOtp['otp'];
          validUntil = DateTime.tryParse(newOtp['valid_until'].toString())?.add(const Duration(hours: 2));
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('otp', newOtp['otp']);
        await prefs.setString('valid_until', validUntil!.toIso8601String());
      } else {
        throw Exception("Invalid OTP format from server.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate OTP: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () {
              final currentOtp = otp ?? "________";

              final fullText = '''
            Totem mode allows unattended parking payment via card. Once configured, a totem does not ask the user to select a zone and only supports card payments. If RFID is enabled, the totem reads the physical card; otherwise, it asks the user to enter the card details manually.

            Instructions for the installer:
            - On the totem device, press "Forgot password" on the login screen
            - Enter 0 (zero) in the email field
            - Insert the OTP received: $currentOtp
            - Select the target zone
            - Confirm the totem location
            - Choose whether the RFID reader is active
            ''';

              final installerOnly = '''
            Instructions for the installer:
            - On the totem device, press "Forgot password" on the login screen
            - Enter 0 (zero) in the email field
            - Insert the OTP received: $currentOtp
            - Select the target zone
            - Confirm the totem location
            - Choose whether the RFID reader is active
            ''';

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Totem setup instructions"),
                  content: SingleChildScrollView(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        children: [
                          const TextSpan(
                            text:
                                "Totem mode allows unattended parking payment via card. Once configured, a totem does not ask the user to select a zone and only supports card payments. If RFID is enabled, the totem reads the physical card; otherwise, it asks the user to enter the card details manually.\n\n",
                          ),
                          const TextSpan(
                            text: "Instructions for the installer:\n",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: "- On the totem device, press \"Forgot password\" on the login screen\n"),
                          const TextSpan(text: "- Enter 0 (zero) in the email field\n"),
                          TextSpan(
                            text: "- Insert the OTP received: ",
                          ),
                          TextSpan(
                            text: currentOtp,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: "\n- Select the target zone\n"),
                          const TextSpan(text: "- Confirm the totem location\n"),
                          const TextSpan(text: "- Choose whether the RFID reader is active"),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: installerOnly));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Installer instructions copied")),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text("Copy instructions"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.info_outline),
            label: const Text("Totem setup instruction"),
          ),
          SizedBox(height:8),
          if (otp != null && validUntil != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "OTP: $otp",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Valid until: ${DateFormat('d/MM/yyyy HH:mm').format(validUntil!)}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: otp!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("OTP copied to clipboard")),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text("Copy"),
                    ),
                  ],
                ),
              ),
            ),
          )
          else
            const Text("No active OTP"),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _generateOtp,
            icon: const Icon(Icons.add),
            label: const Text("Generate New OTP"),
          ),
        ],
      ),
    );
  }
}