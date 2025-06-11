import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../API/client.dart';

class TotemMapAdminPage extends StatefulWidget {
  const TotemMapAdminPage({super.key});

  @override
  State<TotemMapAdminPage> createState() => _TotemMapAdminPageState();
}

class _TotemMapAdminPageState extends State<TotemMapAdminPage> {
  List<Map<String, dynamic>> _totems = [];
  bool loading = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadTotems();
  }

  Future<void> _loadTotems() async {
    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final zoneIds = prefs.getStringList("zone_ids") ?? [];

      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      final List<String> macs = prefs.getStringList("totem_macs") ?? [];

      List<Map<String, dynamic>> filteredTotems = [];

      for (String mac in macs) {
        final response = await dio.get('/totems/config', queryParameters: {'id': mac});
        final t = response.data;

        if (zoneIds.contains(t['zone_id'].toString())) {
          filteredTotems.add(t);
        }
      }

      setState(() {
        _totems = filteredTotems;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load totems: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _totems.isNotEmpty
                    ? LatLng(_totems.first['latitude'], _totems.first['longitude'])
                    : LatLng(45.06, 7.66),
                zoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: _totems
                      .map(
                        (totem) => Marker(
                          point: LatLng(totem['latitude'], totem['longitude']),
                          width: 40,
                          height: 40,
                          child: Tooltip(
                            message: "Totem: ${totem['id']}",
                            child: const Icon(Icons.location_on, color: Colors.deepPurple, size: 38),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }
}
