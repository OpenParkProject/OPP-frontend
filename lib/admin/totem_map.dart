import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/client.dart';

class TotemMapAdminPage extends StatefulWidget {
  const TotemMapAdminPage({super.key});

  @override
  State<TotemMapAdminPage> createState() => _TotemMapAdminPageState();
}

class _TotemMapAdminPageState extends State<TotemMapAdminPage> {
  List<Map<String, dynamic>> _totems = [];
  bool loading = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadTotems();
  }

  Future<void> _loadTotems() async {
    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final zoneIds = prefs.getStringList("zone_ids") ?? [];

      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      final response = await dio.get('/totems');
      final rawData = response.data;

      // Safe handling of null or unexpected formats
      if (rawData == null) {
        setState(() {
          _totems = [];
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No totems available.")),
        );
        return;
      }

      if (rawData is List) {
        final allTotems = List<Map<String, dynamic>>.from(rawData);
        final filteredTotems = allTotems.where((t) =>
          zoneIds.contains(t['zone_id'].toString())
        ).toList();

        setState(() {
          _totems = filteredTotems;
          loading = false;
        });
      } else {
        throw Exception("Invalid totem response format: expected List or null");
      }
    } catch (e, stacktrace) {
      setState(() => loading = false);
      debugPrint('Totem loading error: $e\n$stacktrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load totems: ${e.toString()}")),
      );
    }
  }

@override
  Widget build(BuildContext context) {
    final defaultCenter = LatLng(45.06, 7.66);
    final firstValidTotem = _totems.firstWhere(
      (t) => t['latitude'] is num && t['longitude'] is num,
      orElse: () => {},
    );

    final initialCenter = (firstValidTotem.containsKey('latitude') && firstValidTotem.containsKey('longitude'))
        ? LatLng(
            (firstValidTotem['latitude'] as num).toDouble(),
            (firstValidTotem['longitude'] as num).toDouble(),
          )
        : defaultCenter;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_totems.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            "No totems available in your assigned zones.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: initialCenter,
          zoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: _totems.map((totem) {
              final lat = totem['latitude'];
              final lng = totem['longitude'];

              if (lat is! num || lng is! num) return null;

              return Marker(
                point: LatLng(lat.toDouble(), lng.toDouble()),
                width: 40,
                height: 40,
                child: Tooltip(
                  message: "Totem: ${totem['id']}",
                  child: const Icon(Icons.location_on, color: Colors.deepPurple, size: 38),
                ),
              );
            }).whereType<Marker>().toList(),
          ),
        ],
      ),
    );
  }
}
