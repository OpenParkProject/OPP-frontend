import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../API/client.dart';

class DriversManagementPage extends StatefulWidget {
  final void Function(String)? onPlateSelected;

  const DriversManagementPage({this.onPlateSelected, super.key});

  @override
  State<DriversManagementPage> createState() => _DriversManagementPageState();
}

class _DriversManagementPageState extends State<DriversManagementPage> {
  List<Map<String, String>> userPlates = [];
  bool loadingPlates = true;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _fetchPlates();
  }

  Future<void> _fetchPlates() async {
    try {
      await DioClient().setAuthToken();
      final response = await DioClient().dio.get("/cars");

      final fetchedCars =
          (response.data as List)
              .map(
                (car) => {
                  "plate": car['plate']?.toString().toUpperCase() ?? '',
                  "model": car['model']?.toString() ?? '',
                  "brand": car['brand']?.toString() ?? '',
                },
              )
              .toList();

      setState(() {
        userPlates = fetchedCars;
        loadingPlates = false;
      });
    } catch (e) {
      String msg = "❌ Failed to load vehicle list.";
      if (e is DioException && e.response?.data is Map) {
        final data = e.response?.data;
        msg = data?['error']?.toString() ?? data?['detail']?.toString() ?? msg;
      }
      setState(() {
        loadingPlates = false;
        _feedbackMessage = msg;
      });
    }
  }

  Future<void> _deleteCar(String plate) async {
    try {
      await DioClient().setAuthToken();
      await DioClient().dio.delete("/cars");

      setState(() => _feedbackMessage = "✅ Vehicles deleted.");
      await _fetchPlates();
    } catch (e) {
      setState(() => _feedbackMessage = "❌ Failed to delete");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (loadingPlates)
              CircularProgressIndicator()
            else if (userPlates.isNotEmpty) ...[
              Text(
                "Registered Plates:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...userPlates.map((car) {
                final plate = car['plate'] ?? '';
                final label =
                    "${car['brand'] ?? ''} ${car['model'] ?? ''}".trim();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child:
                      widget.onPlateSelected != null
                          ? ListTile(
                            leading: Icon(Icons.directions_car),
                            title: Text(
                              plate,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(label),
                            trailing: Icon(Icons.arrow_forward),
                            onTap: () => widget.onPlateSelected!(plate),
                          )
                          : ListTile(
                            leading: Icon(Icons.directions_car),
                            title: Text(
                              plate,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(label),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCar(plate),
                                ),
                              ],
                            ),
                          ),
                );
              }),
              Divider(),
            ],
            if (_feedbackMessage != null) ...[
              SizedBox(height: 20),
              Text(_feedbackMessage!, style: TextStyle(color: Colors.blue)),
            ],
          ],
        ),
      ),
    );
  }
}
