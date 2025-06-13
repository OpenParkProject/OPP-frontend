import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../API/client.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../utils/totem_config_manager.dart';
import '../login.dart';

class TotemInstallPage extends StatefulWidget {
  final List<Map<String, dynamic>> enabledZones;
  final String otp;

  const TotemInstallPage({
    required this.enabledZones,
    required this.otp,
    super.key,
  });

  @override
  State<TotemInstallPage> createState() => _TotemInstallPageState();
}

class _TotemInstallPageState extends State<TotemInstallPage> {
  LatLng? _currentLocation;
  String? _macAddress;
  bool _rfidEnabled = false;
  Map<String, dynamic>? _selectedZone;

  @override
  void initState() {
    super.initState();
    _fetchLocationFromIP();
    _fetchMacAddress();
  }

  Future<void> _fetchMacAddress() async {
    try {
      if (!Platform.isLinux && !Platform.isWindows) {
        setState(() => _macAddress = "Unsupported OS");
        return;
      }

      // Comando per ottenere MAC
      final result = await Process.run(
        Platform.isLinux ? 'cat' : 'getmac',
        Platform.isLinux ? ['/sys/class/net/eth0/address'] : [],
      );

      if (result.exitCode == 0) {
        final raw = result.stdout.toString().trim();
        final mac = Platform.isWindows
            ? raw.split('\n').firstWhere((line) => line.contains('-'), orElse: () => 'unknown').split(' ').first.trim()
            : raw;

        setState(() => _macAddress = mac);
      } else {
        setState(() => _macAddress = "Unavailable");
      }
    } catch (e) {
      setState(() => _macAddress = "Error");
    }
  }

  Future<void> _fetchLocationFromIP() async {
    try {
      final res = await http.get(Uri.parse('http://ip-api.com/json/'));
      final data = jsonDecode(res.body);
      setState(() {
        _currentLocation = LatLng(data['lat'], data['lon']);
      });
    } catch (_) {
      setState(() => _currentLocation = LatLng(45.0, 9.0));
    }
  }

  void _confirmInstallation() async {
    if (_currentLocation == null || _selectedZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a zone and wait for the location.")),
      );
      return;
    }

    try {
      final dio = DioClient().dio;
      final zoneId = _selectedZone!['id'];

      // 3. Invia la richiesta POST
      final payload = {
        "id": _macAddress ?? "unknown",
        "zone_id": zoneId,
        "latitude": _currentLocation!.latitude,
        "longitude": _currentLocation!.longitude,
        "otp": widget.otp,
      };

      await dio.post('/totems', data: payload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Totem registered successfully!")),
      );

      // Salva anche la configurazione locale
      await TotemConfigManager.save(
        zoneId: zoneId,
        zoneName: _selectedZone!['name'],
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        rfidEnabled: _rfidEnabled,
      );

      // Restart login page to show totem mode
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (_) => false,);


    } catch (e) {
      String msg = "Installation failed.";
      if (e is DioError && e.response != null) {
        msg += " (${e.response?.statusCode})";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Install Totem')),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Totem ID:", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          SelectableText(_macAddress ?? "Loading MAC..."),
                          const SizedBox(height: 16),
                          const Text("Adjust totem location on map:", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 350,
                            child: FlutterMap(
                              options: MapOptions(
                                center: _currentLocation,
                                zoom: 15.0,
                                onTap: (_, latLng) => setState(() => _currentLocation = latLng),
                              ),
                              children: [
                                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                                if (_currentLocation != null)
                                  MarkerLayer(markers: [
                                    Marker(
                                      width: 40,
                                      height: 40,
                                      point: _currentLocation!,
                                      child: const Icon(Icons.location_on, color: Colors.red),
                                    )
                                  ])
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text("Select installation zone:", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedZone,
                            hint: const Text("Choose a zone"),
                            items: widget.enabledZones.map((zone) {
                              return DropdownMenuItem(
                                value: zone,
                                child: Text("Zone ${zone['id']} - ${zone['name']}"),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedZone = val),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: _rfidEnabled,
                                onChanged: (val) => setState(() => _rfidEnabled = val ?? false),
                              ),
                              const Expanded(
                                child: Text("Enable RFID card reading for this totem"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _confirmInstallation,
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                              child: const Text("Confirm Installation", style: TextStyle(fontSize: 16)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
