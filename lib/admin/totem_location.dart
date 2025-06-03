import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TotemLocationPage extends StatefulWidget {
  const TotemLocationPage({super.key});

  @override
  State<TotemLocationPage> createState() => _TotemLocationPageState();
}

class _TotemLocationPageState extends State<TotemLocationPage> {
  final LatLng _center = LatLng(45.064557, 7.658081);

  final List<LatLng> _parkingLocations = [
    LatLng(45.060447, 7.654317),
    LatLng(45.058225, 7.653149),
    LatLng(45.068145, 7.657488),
    LatLng(45.072882, 7.666789),
    LatLng(45.073395, 7.671776),
    LatLng(45.067507, 7.672143),
    LatLng(45.062762, 7.677981),
    LatLng(45.066525, 7.681563),
    LatLng(45.065594, 7.681796),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Totem Locations')),
      body: FlutterMap(
        options: MapOptions(
          center: _center,
          zoom: 14.0,
          minZoom: 3.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers:
                _parkingLocations
                    .asMap()
                    .entries
                    .map(
                      (entry) => Marker(
                        width: 40,
                        height: 40,
                        point: entry.value,
                        child: Tooltip(
                          message: 'Totems ${entry.key + 1}',
                          child: const Icon(
                            Icons.local_parking,
                            color: Colors.blue,
                            size: 36,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}
