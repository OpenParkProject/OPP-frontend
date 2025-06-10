import 'package:flutter/material.dart';
import '../API/client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openpark/admin/zone_map.dart';
import 'package:openpark/admin/zone_status.dart';

class AssignedZonesPage extends StatefulWidget {
  final String username;
  const AssignedZonesPage({super.key, required this.username});

  @override
  State<AssignedZonesPage> createState() => _AssignedZonesPageState();
}

class _AssignedZonesPageState extends State<AssignedZonesPage> {
  List<ParkingZone> assignedZones = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchAssignedZones();
  }

  Future<void> _fetchAssignedZones() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList("zone_ids") ?? [];

      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      List<ParkingZone> zones = [];

      for (String id in ids) {
        final res = await dio.get('/zones/$id');
        final zone = ParkingZone.fromJson(res.data);
        zones.add(zone);
      }

      setState(() {
        assignedZones = zones;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = "Errore nel caricamento delle zone: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error!));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: assignedZones.length,
        itemBuilder: (context, index) {
          final zone = assignedZones[index];
          return Card(
            child: ListTile(
              title: Text(zone.name),
              subtitle: Text("Zone ID: ${zone.id}"),
              trailing: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ZoneMapPage(zone: zone)),
                  );
                },
                child: const Text("View on map"),
              ),
            ),
          );
        },
      ),
    );
  }
}