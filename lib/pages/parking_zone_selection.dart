import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../db/db_zones.dart';
import 'parking_duration.dart';

class ParkingZoneSelectionPage extends StatefulWidget {
  @override
  State<ParkingZoneSelectionPage> createState() => _ParkingZoneSelectionPageState();
}

class _ParkingZoneSelectionPageState extends State<ParkingZoneSelectionPage> {
  double? userLat;
  double? userLong;
  List<Map<String, dynamic>> zonesWithDistance = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
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

    _calculateDistances();
  }

  void _calculateDistances() {
    List<ParkingZone> zones = ZoneDB.zones;
    zonesWithDistance = zones.map((zone) {
      double distanceMeters = Geolocator.distanceBetween(
        userLat!, userLong!, zone.latitude, zone.longitude,
      );
      return {
        'zone': zone,
        'distance': distanceMeters,
      };
    }).toList();

    zonesWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));

    setState(() {}); // aggiorna l'interfaccia
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Parking Zone')),
      body: userLat == null || userLong == null
          ? Center(child: CircularProgressIndicator())
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
                          title: Text(zone.name),
                          subtitle: Text("€${zone.hourlyRate.toStringAsFixed(2)}/hr • ${(distance / 1000).toStringAsFixed(2)} km"),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ParkingDurationPage(zone: zone),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
