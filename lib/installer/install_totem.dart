import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'qr_scanner.dart';
import 'dart:io';

bool get isQRScannerEnabled => Platform.isAndroid || Platform.isIOS;

class InstallTotemPage extends StatefulWidget {
  final String username;
  const InstallTotemPage({required this.username});

  @override
  State<InstallTotemPage> createState() => _InstallTotemPageState();
}

class _InstallTotemPageState extends State<InstallTotemPage> {
  String? scannedMac;
  DateTime? scannedTimestamp;
  Position? currentPosition;

  final TextEditingController locationLabelController = TextEditingController();
  String? selectedCity;
  String? selectedZone;

  Future<void> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    currentPosition = await Geolocator.getCurrentPosition();
    setState(() {});
  }

  void _scanQrAndExtractData() async {
    if (!isQRScannerEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("QR Scanner is not supported on this platform")),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QrScannerPage()),
    );

    if (result != null && result is Map) {
      scannedMac = result['mac'];
      scannedTimestamp = DateTime.fromMillisecondsSinceEpoch(result['timestamp'] * 1000);
      setState(() {});
      _getCurrentPosition();
    }
  }


  void _submitForm() {
    if (scannedMac == null || selectedCity == null || selectedZone == null || currentPosition == null) return;

    final now = DateTime.now();
    final duration = now.difference(scannedTimestamp!);
    if (duration.inMinutes > 5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("QR code expired")));
      return;
    }

    // TODO: send data to backend
    print("Submitting:");
    print("MAC: $scannedMac");
    print("City: $selectedCity, Zone: $selectedZone");
    print("Label: ${locationLabelController.text}");
    print("LatLng: ${currentPosition!.latitude}, ${currentPosition!.longitude}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Install Totem")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ElevatedButton(
              onPressed: _scanQrAndExtractData,
              child: Text("Scan Totem QR Code"),
            ),
            if (scannedMac != null) ...[
              Text("MAC: $scannedMac"),
              Text("Timestamp: ${scannedTimestamp.toString()}"),
              SizedBox(height: 10),
              TextField(
                controller: locationLabelController,
                decoration: InputDecoration(labelText: "Location label"),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCity,
                items: ["TORINO", "MILANO"].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => selectedCity = val),
                decoration: InputDecoration(labelText: "City"),
              ),
              DropdownButtonFormField<String>(
                value: selectedZone,
                items: ["CENTRO", "NORD"].map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                onChanged: (val) => setState(() => selectedZone = val),
                decoration: InputDecoration(labelText: "Zone"),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: Icon(Icons.send),
                label: Text("Register Totem"),
              )
            ]
          ],
        ),
      ),
    );
  }
}
