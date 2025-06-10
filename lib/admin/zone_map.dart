import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'zone_status.dart';

class ZoneMapPage extends StatelessWidget {
  final ParkingZone zone;

  const ZoneMapPage({super.key, required this.zone});

  List<LatLng> _getPolygonPoints() {
    try {
      final geometryData = jsonDecode(zone.geometry);

      if (geometryData['type'] == 'Polygon') {
        return List<LatLng>.from(
          geometryData['coordinates'][0].map<LatLng>(
            (coord) => LatLng(coord[1], coord[0]),
          ),
        );
      } else if (geometryData['type'] == 'MultiPolygon') {
        return List<LatLng>.from(
          geometryData['coordinates'][0][0].map<LatLng>(
            (coord) => LatLng(coord[1], coord[0]),
          ),
        );
      } else {
        debugPrint("Unsupported geometry type: ${geometryData['type']}");
        return [];
      }
    } catch (e) {
      debugPrint("Error decoding geometry: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = _getPolygonPoints();
    final center = LatLng(zone.latitude ?? 0.0, zone.longitude ?? 0.0);

    return Scaffold(
      appBar: AppBar(
        title: Text("Zone ${zone.id}: ${zone.name}"),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: center,
          zoom: 16,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.openpark',
          ),
          PolygonLayer(
            polygons: [
              Polygon(
                points: points,
                borderColor: Colors.blue,
                borderStrokeWidth: 3,
                color: Colors.blue.withOpacity(0.2),
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on, color: Colors.red, size: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
