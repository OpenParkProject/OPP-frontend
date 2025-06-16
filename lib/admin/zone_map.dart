import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'zone_status.dart';

class ZoneMapPage extends StatelessWidget {
  final ParkingZone zone;
  final LatLng? userLocation;
  const ZoneMapPage({super.key, required this.zone, this.userLocation});

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

    // Includi posizione utente nei bounds se presente
    final allPoints = [
      ...points,
      if (userLocation != null) userLocation!,
    ];

    final bounds = LatLngBounds.fromPoints(allPoints);

    return Scaffold(
      appBar: AppBar(
        title: Text("Zone ${zone.id}: ${zone.name}"),
      ),
      body: FlutterMap(
        options: MapOptions(
          bounds: bounds,
          boundsOptions: const FitBoundsOptions(
            padding: EdgeInsets.all(50),
            maxZoom: 17,
          ),
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
                borderColor: Colors.blueAccent,
                borderStrokeWidth: 3,
                color: Colors.blue.withOpacity(0.25),
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              // Marker zona
              Marker(
                point: LatLng(zone.latitude ?? 0.0, zone.longitude ?? 0.0),
                width: 180,
                height: 70,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: "${zone.name}\n€${zone.priceOffset} + €${zone.priceLin}/h + €${zone.priceExp}exp",
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(color: Colors.white),
                      child: const Icon(Icons.location_on, color: Colors.red, size: 38),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          )
                        ],
                      ),
                      child: Text(
                        zone.name,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Marker utente (se presente)
              if (userLocation != null)
                Marker(
                  point: userLocation!,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
