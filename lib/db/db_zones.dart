import 'package:flutter/services.dart' show rootBundle;

class ParkingZone {
  final String name;
  final double hourlyRate;
  final double latitude;
  final double longitude;

  ParkingZone(this.name, this.hourlyRate, this.latitude, this.longitude);
}

class ZoneDB {
  static List<ParkingZone> zones = [];

  static Future<void> loadZones() async {
    try {
      final csvString = await rootBundle.loadString('assets/data/db_zones.csv');
      final lines = csvString.split('\n').where((l) => l.trim().isNotEmpty).toList();

      zones = lines.skip(1).map((line) {
        final parts = line.split(',');
        return ParkingZone(
          parts[0].trim(),
          double.parse(parts[1]),
          double.parse(parts[2]),
          double.parse(parts[3]),
        );
      }).toList();
    } catch (e) {
      print('Failed to load zones: $e');
      zones = [];
    }
  }

  static List<ParkingZone> sortedByDistance(double userLat, double userLong) {
    zones.sort((a, b) {
      final distA = _distance(userLat, userLong, a.latitude, a.longitude);
      final distB = _distance(userLat, userLong, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });
    return zones;
  }

  static double _distance(double lat1, double lon1, double lat2, double lon2) {
    return ((lat1 - lat2) * (lat1 - lat2)) + ((lon1 - lon2) * (lon1 - lon2));
  }
}