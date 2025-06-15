import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:openpark/API/client.dart';
import 'package:openpark/admin/add_zone.dart';
import 'package:universal_platform/universal_platform.dart';
import 'zone_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'zones_map_all.dart';

class ParkingZone {
  final String name;
  final bool available;
  final String geometry;
  final Map<String, dynamic> metadata;
  final double priceOffset;
  final double priceLin;
  final double priceExp;
  final int id;
  final String createdAt;
  final String updatedAt;
  
  String? assignedBy;

  // Derived properties
  double? latitude;
  double? longitude;
  
  ParkingZone({
    required this.name,
    required this.available,
    required this.geometry,
    required this.metadata,
    required this.priceOffset,
    required this.priceLin, 
    required this.priceExp,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.assignedBy,
  }) {
    _extractCoordinates();
  }

  // Extract center coordinates from geometry
  void _extractCoordinates() {
    try {
      final geometryData = jsonDecode(geometry);
      List<List<double>> coords;
      
      if (geometryData['type'] == 'Polygon') {
        coords = List<List<double>>.from(geometryData['coordinates'][0].map(
          (coord) => List<double>.from(coord)
        ));
      } else if (geometryData['type'] == 'MultiPolygon') {
        // For MultiPolygon, take the first polygon's coordinates
        coords = List<List<double>>.from(geometryData['coordinates'][0][0].map(
          (coord) => List<double>.from(coord)
        ));
      } else {
        debugPrint('Unsupported geometry type: ${geometryData['type']}');
        latitude = 0;
        longitude = 0;
        return;
      }
      
      // Calculate center point of polygon
      double sumLat = 0;
      double sumLng = 0;
      int numPoints = coords.length - 1; // Last point is same as first in closed polygon
      
      for (int i = 0; i < numPoints; i++) {
        sumLng += coords[i][0];
        sumLat += coords[i][1];
      }
      
      latitude = sumLat / numPoints;
      longitude = sumLng / numPoints;
    } catch (e) {
      debugPrint('Error parsing geometry: $e');
      // Default coordinates if parsing fails
      latitude = 0;
      longitude = 0;
    }
  }

  // Calculate hourly rate based on the pricing formula
  double get hourlyRate => priceOffset + priceLin;

  factory ParkingZone.fromJson(Map<String, dynamic> json) {
    return ParkingZone(
      name: json['name'] as String,
      available: json['available'] as bool,
      geometry: json['geometry'] as String,
      metadata: json['metadata'] is String 
          ? jsonDecode(json['metadata']) 
          : (json['metadata'] as Map<String, dynamic>),
      priceOffset: (json['price_offset'] as num).toDouble(),
      priceLin: (json['price_lin'] as num).toDouble(),
      priceExp: (json['price_exp'] as num).toDouble(),
      id: json['id'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class ParkingZoneStatusPage extends StatefulWidget {
  @override
  State<ParkingZoneStatusPage> createState() => _ParkingZoneStatusPageState();
}

class _ParkingZoneStatusPageState extends State<ParkingZoneStatusPage> {
  double? userLat;
  double? userLong;
  List<Map<String, dynamic>> zonesWithDistance = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Move async operations to a separate method
  Future<void> _loadData() async {
    await _determinePosition();
    await _fetchZonesAndCalculateDistances();
  }

  Future<void> _determinePosition() async {
    debugPrint("Determining position");
    if (UniversalPlatform.isLinux || UniversalPlatform.isWeb || UniversalPlatform.isWindows) {
      await getLocationFromIP();
    } else if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        userLat = position.latitude;
        userLong = position.longitude;
      });
    }
  }

  Future<void> getLocationFromIP() async {
    http.Response? response;
    try {
      response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 3));
    } on TimeoutException catch (_) {
      debugPrint('Timeout IP location – using fallback Torino');
      setState(() {
        userLat = 45.0703;
        userLong = 7.6869;
      });
      return;
    } catch (e) {
      debugPrint('Error fetching IP location: $e');
      setState(() {
        userLat = 45.0703;
        userLong = 7.6869;
      });
      return;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        userLat = data['latitude'] ?? 45.0703;
        userLong = data['longitude'] ?? 7.6869;
      });
    } else {
      debugPrint('Failed to get location – fallback Torino');
      setState(() {
        userLat = 45.0703;
        userLong = 7.6869;
      });
    }
  }

  Future<void> _fetchZonesAndCalculateDistances() async {
    debugPrint("Fetching zones and calculating distances...");
    if (userLat == null || userLong == null) {
      debugPrint('Cannot calculate distances: coordinates not available yet');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList("zone_ids") ?? [];

      if (ids.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No assigned/created zones.';
          zonesWithDistance = [];
        });
        return;
      }

      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      List<ParkingZone> zones = [];
      for (String id in ids) {
        final res = await dio.get('/zones/$id');
        zones.add(ParkingZone.fromJson(res.data));
      }

      // Solo zone con coordinate valide
      zones = zones.where((z) => z.latitude != null && z.longitude != null).toList();

      // Calcolo distanza e ordinamento
      zonesWithDistance = zones.map((zone) {
        double distanceMeters = Geolocator.distanceBetween(
          userLat!,
          userLong!,
          zone.latitude!,
          zone.longitude!,
        );
        return {'zone': zone, 'distance': distanceMeters};
      }).toList();

      zonesWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching zones: $e');
    }
  }

  Future<void> _addZone() async {
    // Navigate to the zone creation page and wait for result
    final result = await Navigator.push(context,
      MaterialPageRoute(builder: (context) => AddZonePage()),
    );
    
    // Refresh the zones list when returning
    if (result == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // ⚠️ Assicura che le modifiche vengano viste subito
      await _fetchZonesAndCalculateDistances();
    }
  }

  Future<void> _deleteZone(int zoneId) async {
    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;
      final response = await dio.delete('/zones/$zoneId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          zonesWithDistance.removeWhere((z) => (z['zone'] as ParkingZone).id == zoneId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Zone deleted')),
        );
      } else {
        debugPrint('Unexpected status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting zone: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete zone')),
      );
    }
  }

  Future<void> _toggleAvailability(ParkingZone zone) async {
    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;
      final response = await dio.patch('/zones/${zone.id}', data: {
        'name': zone.name,
        'available': !zone.available,
        'geometry': zone.geometry,
        'metadata': zone.metadata,
        'price_offset': zone.priceOffset,
        'price_lin': zone.priceLin,
        'price_exp': zone.priceExp,
      });
      if (response.statusCode == 200) {
        await _fetchZonesAndCalculateDistances();
      }
    } catch (e) {
      debugPrint('Error updating availability: $e');
    }
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    body: userLat == null || userLong == null
        ? Center(child: CircularProgressIndicator())
        : isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 72, color: Colors.grey.shade400),
                      SizedBox(height: 16),
                      Text(
                        errorMessage ?? 'No zones available',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addZone,
                        icon: Icon(Icons.add_location_alt_rounded),
                        label: Text("Add new zone"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          textStyle: TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Your position:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("$userLat, $userLong\n"),
                        Text("Available zones (nearest first):",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: zonesWithDistance.length,
                            itemBuilder: (context, index) {
                              final zone = zonesWithDistance[index]['zone'] as ParkingZone;
                              final distance = zonesWithDistance[index]['distance'] as double;

                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.symmetric(vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isSmall = constraints.maxWidth < 450;

                                      final buttons = [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ZoneMapPage(zone: zone),
                                              ),
                                            );
                                          },
                                          child: Text("See on map"),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Delete zone',
                                          onPressed: () async {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text('Delete Zone'),
                                                content: Text('Are you sure you want to delete "${zone.name}"?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirmed == true) await _deleteZone(zone.id);
                                          },
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Switch(
                                              value: zone.available,
                                              onChanged: (_) => _toggleAvailability(zone),
                                              activeColor: Colors.green,
                                              inactiveThumbColor: Colors.red,
                                            ),
                                            Text(
                                              zone.available ? 'Active' : 'Inactive',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: zone.available ? Colors.green : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ];

                                      if (isSmall) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              zone.name,
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              "• Price: offset €${zone.priceOffset.toStringAsFixed(2)}, "
                                              "linear €${zone.priceLin.toStringAsFixed(2)}, "
                                              "exp €${zone.priceExp.toStringAsFixed(2)}",
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            Text("• Distance: ${(distance / 1000).toStringAsFixed(2)} km"),
                                            Text("• Zone ID: ${zone.id}"),
                                            Text("Max hours: ${zone.metadata['max_hours'] ?? 'No limit'}",
                                                style: TextStyle(fontSize: 12)),
                                            if (zone.metadata['special_rules'] != null)
                                              Text("Note: ${zone.metadata['special_rules']}",
                                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                            Divider(thickness: 1, height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: buttons,
                                            ),
                                          ],
                                        );
                                      } else {
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    zone.name,
                                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    "• Price: offset €${zone.priceOffset.toStringAsFixed(2)}, "
                                                    "linear €${zone.priceLin.toStringAsFixed(2)}, "
                                                    "exp €${zone.priceExp.toStringAsFixed(2)}",
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                                  Text("• Distance: ${(distance / 1000).toStringAsFixed(2)} km"),
                                                  Text("• Zone ID: ${zone.id}"),
                                                  Text("Max hours: ${zone.metadata['max_hours'] ?? 'No limit'}",
                                                      style: TextStyle(fontSize: 12)),
                                                  if (zone.metadata['special_rules'] != null)
                                                    Text("Note: ${zone.metadata['special_rules']}",
                                                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              height: 100,
                                              margin: EdgeInsets.symmetric(horizontal: 12),
                                              color: Colors.grey.shade300,
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: buttons.map((b) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 6),
                                                child: b,
                                              )).toList(),
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _addZone,
                            icon: Icon(Icons.add_location_alt_rounded),
                            label: Text("Add new zone"),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              textStyle: TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
  );
}
}