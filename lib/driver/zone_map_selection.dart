import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:openpark/API/client.dart';
import 'package:openpark/admin/zone_status.dart';
import 'my_cars.dart';
import 'plate_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZoneMapSelectionPage extends StatefulWidget {
  final bool fromGuest;
  final LatLng? userLocation;
  const ZoneMapSelectionPage({super.key, this.fromGuest = false, this.userLocation});

  @override
  State<ZoneMapSelectionPage> createState() => _ZoneMapSelectionPageState();
}

class _ZoneMapSelectionPageState extends State<ZoneMapSelectionPage> {
  List<ParkingZone> zones = [];
  bool loading = true;


  List<Color> _generateZoneColors(int count) {
    final rand = Random(12345);
    return List.generate(count, (_) {
      return Color.fromARGB(100, rand.nextInt(200) + 30, rand.nextInt(200) + 30, rand.nextInt(200) + 30);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

  Future<void> _fetchZones() async {
    try {
      await DioClient().setAuthToken();
      final response = await DioClient().dio.get("/zones");
      final List<ParkingZone> parsed = (response.data as List)
          .map((z) => ParkingZone.fromJson(z))
          .toList();
      setState(() {
        zones = parsed;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading zones: $e");
      setState(() {
        loading = false;
      });
    }
  }

  List<LatLng> _extractPolygon(ParkingZone zone) {
    final data = jsonDecode(zone.geometry);
    if (data['type'] == 'Polygon') {
      return List<LatLng>.from(data['coordinates'][0].map((c) => LatLng(c[1], c[0])));
    } else if (data['type'] == 'MultiPolygon') {
      return List<LatLng>.from(data['coordinates'][0][0].map((c) => LatLng(c[1], c[0])));
    }
    return [];
  }


  @override
  Widget build(BuildContext context) {
    final colors = _generateZoneColors(zones.length);

    LatLngBounds? bounds;

    if (widget.userLocation != null && zones.isNotEmpty) {
      final user = widget.userLocation!;

      // Trova la zona più vicina all'utente
      zones.sort((a, b) {
        final d1 = Distance().as(LengthUnit.Meter, user, LatLng(a.latitude!, a.longitude!));
        final d2 = Distance().as(LengthUnit.Meter, user, LatLng(b.latitude!, b.longitude!));
        return d1.compareTo(d2);
      });

      final nearestZone = zones.first;
      final zonePolygon = _extractPolygon(nearestZone);

      if (zonePolygon.isNotEmpty) {
        bounds = LatLngBounds(zonePolygon.first, widget.userLocation!);

        // Includes all points in the poligon zone
        for (final point in zonePolygon) {
          bounds.extend(point);
        }

        // Includes user's location
        bounds.extend(user);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Choose a zone on the map")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
          options: MapOptions(
            bounds: bounds,
            boundsOptions: const FitBoundsOptions(
              padding: EdgeInsets.all(60),
              maxZoom: 16,
            ),
            center: const LatLng(45.07, 7.68), // fallback
            zoom: 13,
          ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.openpark',
                ),
                PolygonLayer(
                  polygons: zones.asMap().entries.map((entry) {
                    final i = entry.key;
                    final zone = entry.value;
                    final color = colors[i];
                    final points = _extractPolygon(zone);
                    return Polygon(
                      points: points,
                      color: color,
                      borderColor: Colors.black,
                      borderStrokeWidth: 1,
                    );
                  }).toList(),
                ),
                MarkerLayer(
                  markers: [
                    if (widget.userLocation != null)
                      Marker(
                        point: widget.userLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                      ),
                    ...zones.asMap().entries.map((entry) {
                      final zone = entry.value;
                      final points = _extractPolygon(zone);

                      final center = points.fold<LatLng>(
                        LatLng(0, 0),
                        (prev, el) => LatLng(prev.latitude + el.latitude, prev.longitude + el.longitude),
                      );
                      final avgCenter = LatLng(center.latitude / points.length, center.longitude / points.length);

                      return Marker(
                        point: avgCenter,
                        width: 140,
                        height: 60,
                        child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Zone: ${zone.name}"),
                              content: Text(
                                "This zone applies a tariff:\n\n"
                                "Cost = offset + (lin × t)^exp\n"
                                "where t is the duration in hours.\n\n"
                                "🔹 Coefficients:\n"
                                "• Offset: €${zone.priceOffset.toStringAsFixed(2)}\n"
                                "• Linear: €${zone.priceLin.toStringAsFixed(2)} / h\n"
                                "• Exponential: ${zone.priceExp.toStringAsFixed(2)}\n"
                                "${zone.metadata['max_hours'] != null ? "\nMax hours: ${zone.metadata['max_hours']}" : ""}",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setInt("selected_zone_id", zone.id);
                                    await DioClient().setAuthToken();
                                    final dio = DioClient().dio;
                                    final response = await dio.get("/users/me");
                                    final username = response.data['username'];

                                    if (!mounted) return;
                                    Navigator.pop(context);

                                    if (username == "guest") {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (_) => const SimplePlateInputPage()),
                                      );
                                    } else {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (_) => const MyCarsPage()),
                                      );
                                    }
                                  },
                                  child: const Text("Select this zone"),
                                ),
                              ],
                            ),
                          );
                        },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, size: 36, color: Colors.red),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
                                ),
                                child: Text(
                                  zone.name,
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
    );
  }
}