import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import '../API/client.dart';
import 'fullscreen_map.dart';

class AddZonePage extends StatefulWidget {
  @override
  _AddZonePageState createState() => _AddZonePageState();
}

class _AddZonePageState extends State<AddZonePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceOffsetController = TextEditingController();
  final _priceLinController = TextEditingController();
  final _priceExpController = TextEditingController();
  final _maxHoursController = TextEditingController();
  final _specialRulesController = TextEditingController();

  bool _available = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Map drawing variables
  final List<LatLng> _polygonPoints = [];
  final MapController _mapController = MapController();
  LatLng _center = LatLng(45.4642, 9.1900); // Default to Milan

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceOffsetController.dispose();
    _priceLinController.dispose();
    _priceExpController.dispose();
    _maxHoursController.dispose();
    _specialRulesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    // You can reuse the location code from zone_statues.dart
    // For now, we'll use a default location
    setState(() {
      _center = LatLng(45.4642, 9.1900); // Milan coordinates
    });
  }

  void _addPoint(LatLng point) {
    setState(() {
      _polygonPoints.add(point);
    });
  }

  void _clearPoints() {
    setState(() {
      _polygonPoints.clear();
    });
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
      });
    }
  }

  String _createGeoJSONPolygon() {
    if (_polygonPoints.length < 3) {
      return ''; // Not enough points for a polygon
    }

    // GeoJSON requires closing the polygon by repeating the first point
    final List<LatLng> closedPolygon = List.from(_polygonPoints);
    if (closedPolygon.first != closedPolygon.last) {
      closedPolygon.add(closedPolygon.first);
    }

    // Convert to GeoJSON format
    final List<List<List<double>>> coordinates = [
      closedPolygon.map((point) => [point.longitude, point.latitude]).toList()
    ];

    final Map<String, dynamic> geoJson = {
      'type': 'Polygon',
      'coordinates': coordinates,
    };

    return jsonEncode(geoJson);
  }

  Future<void> _submitZone() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String geometryJson = _createGeoJSONPolygon();
    if (geometryJson.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please draw a polygon with at least 3 points')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;
      
      // Create metadata
      final Map<String, dynamic> metadata = {};
      if (_maxHoursController.text.isNotEmpty) {
        metadata['max_hours'] = int.parse(_maxHoursController.text);
      }
      if (_specialRulesController.text.isNotEmpty) {
        metadata['special_rules'] = _specialRulesController.text;
      }

      // Create zone data
      final Map<String, dynamic> zoneData = {
        'name': _nameController.text,
        'available': _available,
        'geometry': geometryJson,
        'metadata': metadata,
        'price_offset': double.parse(_priceOffsetController.text),
        'price_lin': double.parse(_priceLinController.text),
        'price_exp': double.parse(_priceExpController.text),
      };

      // Submit to API
      final response = await dio.post('/zones', data: zoneData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Zone created successfully')),
        );
        Navigator.pop(context, true); // Return success to previous screen
      } else {
        setState(() {
          _errorMessage = 'Failed to create zone: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating zone: $e';
      });
      debugPrint('Error creating zone: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Parking Zone'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _submitZone,
            tooltip: 'Save Zone',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map for drawing the zone
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.map),
                        label: Text("Draw Zone on Map"),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullscreenMapPage(initialPoints: _polygonPoints),
                            ),
                          );
                          if (result != null && result is List<LatLng>) {
                            setState(() {
                              _polygonPoints
                                ..clear()
                                ..addAll(result);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                   // Form for zone details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zone Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          
                          // Basic info
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Zone Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Pricing
                          Text(
                            'Pricing',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceOffsetController,
                                  decoration: InputDecoration(
                                    labelText: 'Base Price (€)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _priceLinController,
                                  decoration: InputDecoration(
                                    labelText: 'Linear Rate (€/h)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _priceExpController,
                            decoration: InputDecoration(
                              labelText: 'Exponential Rate',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Additional options
                          Text(
                            'Additional Options',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          
                          TextFormField(
                            controller: _maxHoursController,
                            decoration: InputDecoration(
                              labelText: 'Maximum Parking Hours (optional)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (int.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _specialRulesController,
                            decoration: InputDecoration(
                              labelText: 'Special Rules (optional)',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., No overnight parking',
                            ),
                            maxLines: 2,
                          ),
                          SizedBox(height: 16),
                          
                          // Availability toggle
                          Row(
                            children: [
                              Text('Zone Available:'),
                              Switch(
                                value: _available,
                                onChanged: (value) {
                                  setState(() {
                                    _available = value;
                                  });
                                },
                              ),
                              Text(_available ? 'Yes' : 'No'),
                            ],
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Submit button
                          ElevatedButton(
                            onPressed: _submitZone,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text(
                              'Create Zone',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}