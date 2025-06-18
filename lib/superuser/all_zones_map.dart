import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:openpark/API/client.dart';
import '../admin/zone_status.dart';

class SuperuserZonesMapPage extends StatefulWidget {
  const SuperuserZonesMapPage({super.key});

  @override
  State<SuperuserZonesMapPage> createState() => _SuperuserZonesMapPageState();
}

class _SuperuserZonesMapPageState extends State<SuperuserZonesMapPage> {
  List<ParkingZone> zones = [];
  Map<int, List<String>> zoneAdmins = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

Future<void> _loadData() async {
  setState(() {
    loading = true;
    zones = [];
    zoneAdmins = {};
  });

  try {
    await DioClient().setAuthToken();
    final dio = DioClient().dio;

    // 1. Recupera tutte le zone
    final res = await dio.get('/zones');
    final List<dynamic> jsonZones = res.data;
    zones = jsonZones.map((z) => ParkingZone.fromJson(z)).toList();

    setState(() => loading = false);
  } catch (e) {
    debugPrint("❌ Error loading zones: $e");
    setState(() => loading = false);
  }
}

  List<Color> _generateZoneColors(int count) {
    final rand = Random(123);
    return List<Color>.generate(count, (_) {
      return Color.fromARGB(140, rand.nextInt(200) + 30, rand.nextInt(200) + 30, rand.nextInt(200) + 30);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    final allPoints = <LatLng>[];
    final zoneColors = _generateZoneColors(zones.length);

    for (var zone in zones) {
      try {
        final geometryData = jsonDecode(zone.geometry);
        List<dynamic> rawCoords;
        if (geometryData['type'] == 'Polygon') {
          rawCoords = geometryData['coordinates'][0];
        } else if (geometryData['type'] == 'MultiPolygon') {
          rawCoords = geometryData['coordinates'][0][0];
        } else {
          continue;
        }
        for (var coord in rawCoords) {
          allPoints.add(LatLng(coord[1], coord[0]));
        }
      } catch (_) {}
    }

    final bounds = LatLngBounds.fromPoints(allPoints);

    return Scaffold(
      appBar: AppBar(title: const Text("All Zones Overview")),
      body: FlutterMap(
        options: MapOptions(
          bounds: bounds,
          boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(80), maxZoom: 16),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          PolygonLayer(
            polygons: zones.asMap().entries.map((entry) {
              final index = entry.key;
              final zone = entry.value;
              final geometryData = jsonDecode(zone.geometry);
              List<List> rawCoords;

              if (geometryData['type'] == 'Polygon') {
                rawCoords = List<List>.from(geometryData['coordinates'][0]);
              } else if (geometryData['type'] == 'MultiPolygon') {
                rawCoords = List<List>.from(geometryData['coordinates'][0][0]);
              } else {
                return null;
              }

              final points = rawCoords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();

              return Polygon(
                points: points,
                color: zoneColors[index],
                borderColor: zoneColors[index].withOpacity(0.8),
                borderStrokeWidth: 2,
              );
            }).whereType<Polygon>().toList(),
          ),
          MarkerLayer(
            markers: zones.asMap().entries.map((entry) {
              final zone = entry.value;
              final status = zone.available ? "Available" : "Unavailable";

              return Marker(
                point: LatLng(zone.latitude!, zone.longitude!),
                width: 200,
                height: 90,
                alignment: Alignment.topCenter,
                child: Tooltip(
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                  textStyle: const TextStyle(color: Colors.white),
                  message: "${zone.name}\n- Id: ${zone.id}\n- Status: $status)",
                  child: Icon(Icons.location_on, color: zone.available ? Colors.green : Colors.red, size: 38),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
