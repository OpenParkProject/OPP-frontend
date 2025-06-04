import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ParkingLot {
  final String name;
  final LatLng location;
  ParkingLot(this.name, this.location);
}

class TotemLocationPage extends StatefulWidget {
  const TotemLocationPage({super.key});

  @override
  State<TotemLocationPage> createState() => _TotemLocationPageState();
}

class _TotemLocationPageState extends State<TotemLocationPage> {
  final LatLng _center = LatLng(45.064557, 7.658081);

  final List<ParkingLot> _parkingLots = [
    ParkingLot('Porta Nuova', LatLng(45.060447, 7.654317)),
    ParkingLot('San Salvario', LatLng(45.058225, 7.653149)),
    ParkingLot('Piazza Statuto', LatLng(45.068145, 7.657488)),
    ParkingLot('Crocetta', LatLng(45.072882, 7.666789)),
    ParkingLot('Politecnico', LatLng(45.073395, 7.671776)),
    ParkingLot('Lingotto', LatLng(45.067507, 7.672143)),
    ParkingLot('Valentino', LatLng(45.062762, 7.677981)),
    ParkingLot('Porta Susa', LatLng(45.066525, 7.681563)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                _parkingLots
                    .map(
                      (lot) => Marker(
                        width: 40,
                        height: 40,
                        point: lot.location,
                        child: Tooltip(
                          message: lot.name,
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
