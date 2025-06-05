import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TotemQRPage extends StatefulWidget {
  @override
  State<TotemQRPage> createState() => _TotemQRPageState();
}

class _TotemQRPageState extends State<TotemQRPage> {
  String macAddress = "B8:27:EB:12:34:56"; // placeholder
  int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  @override
  void initState() {
    super.initState();
    _loadMac();
  }

  Future<void> _loadMac() async {
    // TODO: replace with real MAC address read logic (es. via platform channel)
    // final deviceInfo = await DeviceInfoPlugin().linuxInfo;
    // macAddress = await getMacAddressSomehow();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      "mac": macAddress,
      "timestamp": timestamp,
    });

    return Scaffold(
      appBar: AppBar(title: Text("Totem Setup")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220.0,
            ),
            SizedBox(height: 20),
            Text("MAC: $macAddress"),
            Text("Timestamp: $timestamp"),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: call backend GET /totems/configure?mac=...
              },
              icon: Icon(Icons.cloud_download),
              label: Text("Register Totem"),
            )
          ],
        ),
      ),
    );
  }
}
