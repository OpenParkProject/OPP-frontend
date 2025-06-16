import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:universal_platform/universal_platform.dart';
import 'package:http/http.dart' as http;
import '../API/client.dart';
import 'plate_input.dart';
import 'my_cars.dart';
import 'create_ticket.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin/zone_map.dart';
import '../admin/zone_status.dart';
import 'package:latlong2/latlong.dart';

class ParkingZoneSelectionPage extends StatefulWidget {
  final bool fromGuest;

  const ParkingZoneSelectionPage({this.fromGuest = false, super.key});

  @override
  State<ParkingZoneSelectionPage> createState() => _ParkingZoneSelectionPageState();
}

class _ParkingZoneSelectionPageState extends State<ParkingZoneSelectionPage> {
  double? userLat;
  double? userLong;
  List<Map<String, dynamic>> zonesWithDistance = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _checkTotemMode();
  }

  Future<void> _checkTotemMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isTotem = prefs.getBool('isTotem') ?? false;

    if (isTotem) {
      final zoneId = prefs.getInt('zone_id');
      final zoneName = prefs.getString('zone_name');
      final offset = double.tryParse(prefs.getString('price_offset') ?? '0') ?? 0;
      final lin = double.tryParse(prefs.getString('price_lin') ?? '0') ?? 0;
      final exp = double.tryParse(prefs.getString('price_exp') ?? '0') ?? 0;

      final dummyZone = ParkingZone(
        id: zoneId ?? 0,
        name: zoneName ?? 'Totem Zone',
        available: true,
        geometry: '{"type":"Polygon","coordinates":[[[0,0],[0,0],[0,0],[0,0]]]}',
        metadata: {},
        priceOffset: offset,
        priceLin: lin,
        priceExp: exp,
        createdAt: '',
        updatedAt: '',
      );

      // recupera username per decidere il flusso
      await DioClient().setAuthToken();
      final response = await DioClient().dio.get("/users/me");
      final username = response.data['username'];

      if (!mounted) return;

      if (username == "guest") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SimplePlateInputPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MyCarsPage(
              onPlateSelected: (plate) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SelectDurationPage(
                      plate: plate,
                      selectedZone: dummyZone,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    } else {
      _determinePosition(); // comportamento normale
    }
  }

  Future<void> _determinePosition() async {
    if (UniversalPlatform.isLinux || UniversalPlatform.isWeb || UniversalPlatform.isWindows) {
      await getLocationFromIP();
    } else if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        userLat = position.latitude;
        userLong = position.longitude;
      });
      
      await _fetchZonesAndCalculateDistances();
    }
  }
  
  Future<void> getLocationFromIP() async {
    http.Response? response;
    try {
      response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Timeout or error fetching IP location: $e – using fallback Torino');
      setState(() {
        userLat = 45.0703;
        userLong = 7.6869;
      });
      await _fetchZonesAndCalculateDistances();
      return;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        userLat = data['latitude'] ?? 45.0703;
        userLong = data['longitude'] ?? 7.6869;
      });
    } else {
      debugPrint('Failed to fetch IP location (status ${response.statusCode}), using fallback');
      setState(() {
        userLat = 45.0703;
        userLong = 7.6869;
      });
    }

    await _fetchZonesAndCalculateDistances();

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
      // Use DioClient singleton instead of http
      await DioClient().setAuthToken();
      final response = await DioClient().dio.get('/zones');
      
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
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching zones: $e';
      });
      debugPrint('Error fetching zones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.fromGuest) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('access_token');
          DioClient().clearAuthToken();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Select Parking Zone')),
        body: isLoading
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
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Your position:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("$userLat, $userLong\n"),
                        Text("Available zones (nearest first):", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: zonesWithDistance.length,
                            itemBuilder: (context, index) {
                              final zone = zonesWithDistance[index]['zone'] as ParkingZone;
                              final distance = zonesWithDistance[index]['distance'] as double;
                              return ListTile(
                                title: Text("${zone.id} - ${zone.name}"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text("€${zone.hourlyRate.toStringAsFixed(2)}/hr • ${(distance / 1000).toStringAsFixed(2)} km"),
                                        SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: Text("Rate for zone ${zone.name}"),
                                                content: Text(
                                                  "This zone applies a tariff calculated as:\n\n"
                                                  "Cost = offset + (lin × t)^exp\n"
                                                  "where t is the duration in hours.\n\n"
                                                  "🔹 Coefficients:\n"
                                                  "• Offset: €${zone.priceOffset.toStringAsFixed(2)}\n"
                                                  "• Linear: €${zone.priceLin.toStringAsFixed(2)} / h\n"
                                                  "• Exponential: ${zone.priceExp.toStringAsFixed(2)}\n\n"
                                                  "➡️ The longer you park, the higher the incremental cost.",
                                                  textAlign: TextAlign.left,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: Text("OK"),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: Icon(Icons.info_outline, size: 18),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "Offset: €${zone.priceOffset.toStringAsFixed(2)} • Lin: €${zone.priceLin.toStringAsFixed(2)} • Exp: ${zone.priceExp.toStringAsFixed(2)}",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    if (zone.metadata['max_hours'] != null)
                                      Text("Max hours: ${zone.metadata['max_hours']}", style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        minimumSize: const Size(10, 36),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ZoneMapPage(
                                              zone: zone,
                                              userLocation: userLat != null && userLong != null
                                                  ? LatLng(userLat!, userLong!)
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.map_outlined, size: 18),
                                      label: const Text("See on Map", style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 30),
                                    Icon(Icons.arrow_forward_ios, size: 16, color: zone.available ? null : Colors.grey),
                                  ],
                                ),
                                enabled: zone.available,
                                onTap: zone.available
                                    ? () async {
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.setInt("selected_zone_id", zone.id);
                                        await DioClient().setAuthToken();
                                        final dio = DioClient().dio;
                                        final response = await dio.get("/users/me");
                                        final username = response.data['username'];

                                        if (!mounted) return;

                                        if (username == "guest") {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => const SimplePlateInputPage()),
                                          );
                                        } else {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const MyCarsPage(),
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}