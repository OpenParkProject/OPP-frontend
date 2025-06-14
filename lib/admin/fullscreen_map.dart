import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class FullscreenMapPage extends StatefulWidget {
  final List<LatLng> initialPoints;

  const FullscreenMapPage({required this.initialPoints, super.key});

  @override
  State<FullscreenMapPage> createState() => _FullscreenMapPageState();
}

class _FullscreenMapPageState extends State<FullscreenMapPage> {
  late List<LatLng> polygonPoints;
  final MapController _mapController = MapController();
  LatLng _center = LatLng(45.4642, 9.1900); // Default to Milan

  @override
  void initState() {
    super.initState();
    polygonPoints = List.from(widget.initialPoints);
    _setInitialLocation();
  }

  Future<void> _setInitialLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) return;
      }

      final position = await Geolocator.getCurrentPosition();
      final current = LatLng(position.latitude, position.longitude);
      setState(() => _center = current);
      _mapController.move(current, 14.0);
    } catch (e) {
      debugPrint("Could not get location: $e");
    }
  }

  void _addPoint(LatLng point) {
    setState(() => polygonPoints.add(point));
  }

  void _clearPoints() {
    setState(() => polygonPoints.clear());
  }

  void _undoLastPoint() {
    if (polygonPoints.isNotEmpty) {
      setState(() => polygonPoints.removeLast());
    }
  }

  void _saveAndReturn() {
    Navigator.pop(context, polygonPoints);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Draw Zone'), actions: [
        IconButton(icon: Icon(Icons.check), onPressed: _saveAndReturn)
      ]),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _center,
              zoom: 14.0,
              onTap: (tapPosition, latLng) => _addPoint(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.openpark.app',
              ),
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: polygonPoints,
                    color: Colors.blue.withOpacity(0.4),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: polygonPoints
                    .map((point) => Marker(
                          width: 30,
                          height: 30,
                          point: point,
                          child: Icon(Icons.location_on, color: Colors.red),
                        ))
                    .toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: _undoLastPoint,
                  child: Icon(Icons.undo),
                  heroTag: null,
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _clearPoints,
                  child: Icon(Icons.clear),
                  heroTag: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
