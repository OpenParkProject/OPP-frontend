import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:openpark/API/client.dart';
import 'package:openpark/admin/add_zone.dart';
import 'package:universal_platform/universal_platform.dart';

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
    if (UniversalPlatform.isLinux || UniversalPlatform.isWeb) {
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
    final response = await http.get(Uri.parse('http://ip-api.com/json/'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        userLat = data['lat'];
        userLong = data['lon'];
      });
    } else {
      debugPrint('Failed to get location from IP: ${response.statusCode}');
      setState(() {
        userLat = 0.0; // Default fallback
        userLong = 0.0; // Default fallback
      });
    }
  }

  Future<void> _fetchZonesAndCalculateDistances() async {
    if (userLat == null || userLong == null) {
      debugPrint('Cannot calculate distances: coordinates not available yet');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;
      // Fetch zones from API
      final response = await dio.get('/zones');
      
      if (response.statusCode == 200) {
        final List<dynamic> zonesData = response.data;
        
        List<ParkingZone> zones = zonesData.map((zoneData) {
          return ParkingZone.fromJson(zoneData as Map<String, dynamic>);
        }).toList();
        
        // Filter out zones with invalid coordinates
        zones = zones.where((zone) => 
          zone.latitude != null && zone.longitude != null).toList();
        
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
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load zones: ${response.statusCode}';
        });
        debugPrint('Failed to load zones: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching zones: $e';
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
      _fetchZonesAndCalculateDistances();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userLat == null || userLong == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Determining your position to find nearby parking zones...",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(child: Text(errorMessage!))
                  : Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your position:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("$userLat, $userLong\n"),
                          Text(
                            "Available zones (nearest first):",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: zonesWithDistance.length,
                              itemBuilder: (context, index) {
                                final zone =
                                    zonesWithDistance[index]['zone'] as ParkingZone;
                                final distance =
                                    zonesWithDistance[index]['distance'] as double;
                                return ListTile(
                                  title: Text(zone.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "€${zone.hourlyRate.toStringAsFixed(2)}/hr • ${(distance / 1000).toStringAsFixed(2)} km",
                                      ),
                                      Text(
                                        "Max hours: ${zone.metadata['max_hours'] ?? 'No limit'}",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      zone.metadata['special_rules'] != null
                                          ? Text(
                                              "Note: ${zone.metadata['special_rules']}",
                                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                            )
                                          : SizedBox.shrink(),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: zone.available ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      zone.available ? 'Available' : 'Full',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 10),
                          TextButton(onPressed: _addZone,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                textStyle: TextStyle(fontSize: 16),
                              ),
                              child: Text("Add zone"),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
