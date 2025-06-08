import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:universal_platform/universal_platform.dart';
import '../../rfid_bridge_client.dart';

class TotemPage extends StatefulWidget {
  @override
  State<TotemPage> createState() => _TotemPageState();
}

class _TotemPageState extends State<TotemPage> {
  String machineId = "00:00:00:00:00:00";
  int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  @override
  void initState() {
    super.initState();
    _loadId();
  }

  Future<void> _loadId() async {
    final deviceInfo = await DeviceInfoPlugin().deviceInfo;
    if (UniversalPlatform.isAndroid) {
      final androidInfo = deviceInfo as AndroidDeviceInfo;
      machineId = androidInfo.id;
    } else if (UniversalPlatform.isIOS) {
      final iosInfo = deviceInfo as IosDeviceInfo;
      machineId = iosInfo.identifierForVendor!;
    } else if (UniversalPlatform.isLinux) {
      final linuxInfo = deviceInfo as LinuxDeviceInfo;
      machineId = linuxInfo.machineId ?? "00:00:00:00:00:00";
    } else if (UniversalPlatform.isMacOS) {
      final macInfo = deviceInfo as MacOsDeviceInfo;
      machineId = macInfo.systemGUID ?? "00:00:00:00:00:00";
    } else if (UniversalPlatform.isWindows) {
      final windowsInfo = deviceInfo as WindowsDeviceInfo;
      machineId = windowsInfo.computerName;
    } else {
      machineId = "00:00:00:00:00:00";
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      "id": machineId,
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
            Text("ID: $machineId"),
            Text("Timestamp: $timestamp"),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: call backend GET /totems/configure?mac=...
              },
              icon: Icon(Icons.cloud_download),
              label: Text("Register Totem Online"),
            ),
            SizedBox(height: 15),
            if (UniversalPlatform.isDesktop)
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await RFID_read();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.$2),
                      backgroundColor: result.$1 ? Colors.green : Colors.red,
                    ),
                  );
                },
                icon: Icon(Icons.nfc),
                label: Text("Register Totem with Card Reader"),
              ),
          ],
        ),
      ),
    );
  }
}
