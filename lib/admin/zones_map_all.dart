import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'zone_status.dart';

class AllZonesMapPage extends StatelessWidget {
  final List<ParkingZone> zones;
  const AllZonesMapPage({super.key, required this.zones});

  // Colori accesi e distinti
  List<Color> _generateZoneColors(int count) {
    final rand = Random(99); // seme diverso
    return List<Color>.generate(count, (_) {
      final r = rand.nextInt(200) + 30;
      final g = rand.nextInt(200) + 30;
      final b = rand.nextInt(200) + 30;
      return Color.fromARGB(150, r, g, b); // opacità più alta
    });
  }

@override
Widget build(BuildContext context) {
  // Includi tutti i vertici dei poligoni per il calcolo del bounds
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
    } catch (e) {
      debugPrint("Errore parsing poligono zona ${zone.name}: $e");
    }
  }

  final bounds = LatLngBounds.fromPoints(allPoints);

  return Scaffold(
    appBar: AppBar(title: const Text("All Zones")),
    body: FlutterMap(
      options: MapOptions(
        bounds: bounds,
        boundsOptions: const FitBoundsOptions(
          padding: EdgeInsets.all(80),
          maxZoom: 16,
        ),
      ),
      children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.openpark',
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

              final points = rawCoords
                  .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
                  .toList();

              return Polygon(
                points: points,
                borderColor: zoneColors[index].withOpacity(0.9),
                borderStrokeWidth: 3,
                color: zoneColors[index],
              );
            }).whereType<Polygon>().toList(),
          ),
          MarkerLayer(
            markers: zones.asMap().entries.map((entry) {
              final index = entry.key;
              final zone = entry.value;
              final markerColor = zoneColors[index].withOpacity(0.9);

              return Marker(
                point: LatLng(zone.latitude!, zone.longitude!),
                width: 180,
                height: 80,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      preferBelow: false,
                      verticalOffset: 5,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: TextStyle(color: Colors.white),
                      message:
                          "${zone.name}\n€${zone.priceOffset} + €${zone.priceLin}/h + €${zone.priceExp}exp",
                      child: Icon(Icons.location_on, color: markerColor, size: 38),
                    ),
                    const SizedBox(height: 2),
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
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
