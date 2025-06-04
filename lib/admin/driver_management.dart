import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../singleton/dio_client.dart';

class DriversManagementPage extends StatefulWidget {
  final void Function(String)? onPlateSelected;

  const DriversManagementPage({this.onPlateSelected, super.key});

  @override
  State<DriversManagementPage> createState() => _DriversManagementPageState();
}

class _DriversManagementPageState extends State<DriversManagementPage> {
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _brandController = TextEditingController();

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
      if (e is DioError && e.response?.data is Map) {
        final data = e.response?.data;
        msg = data?['error']?.toString() ?? data?['detail']?.toString() ?? msg;
      }
      setState(() {
        loadingPlates = false;
        _feedbackMessage = msg;
      });
    }
  }

  Future<void> _addCar() async {
    final plate = _plateController.text.trim().toUpperCase();
    final model = _modelController.text.trim();
    final brand = _brandController.text.trim();

    if (plate.isEmpty || brand.isEmpty || model.isEmpty) {
      setState(() => _feedbackMessage = "❗ Please fill all fields.");
      return;
    }

    try {
      await DioClient().setAuthToken();
      await DioClient().dio.post(
        "/cars",
        data: {"plate": plate, "brand": brand, "model": model},
      );

      setState(() {
        _feedbackMessage = "✅ Vehicle $plate registered successfully.";
        _plateController.clear();
        _brandController.clear();
        _modelController.clear();
      });

      await _fetchPlates();
    } catch (e) {
      String msg = "❌ Failed to register vehicle.";
      if (e is DioError && e.response?.data is Map) {
        final data = e.response?.data;
        msg = "❌ ${data?['error'] ?? data?['detail'] ?? 'Unknown error'}";
      }
      setState(() => _feedbackMessage = msg);
    }
  }

  Future<void> _deleteCar(String plate) async {
    try {
      await DioClient().setAuthToken();
      await DioClient().dio.delete("/cars/$plate");

      setState(() => _feedbackMessage = "✅ Vehicle $plate deleted.");
      await _fetchPlates();
    } catch (e) {
      setState(() => _feedbackMessage = "❌ Failed to delete $plate");
    }
  }

  Future<void> _editCar(String oldPlate, String brand, String model) async {
    try {
      await DioClient().setAuthToken();
      await DioClient().dio.patch(
        "/cars/$oldPlate",
        data: {"plate": oldPlate, "brand": brand, "model": model},
      );

      setState(() => _feedbackMessage = "✅ $oldPlate updated.");
      await _fetchPlates();
    } catch (e) {
      setState(() => _feedbackMessage = "❌ Failed to update $oldPlate");
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
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _brandController.text = car['brand'] ?? '';
                                    _modelController.text = car['model'] ?? '';
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text("Edit $plate"),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: _brandController,
                                                  decoration: InputDecoration(
                                                    labelText: "Brand",
                                                  ),
                                                ),
                                                TextField(
                                                  controller: _modelController,
                                                  decoration: InputDecoration(
                                                    labelText: "Model",
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: Text("Cancel"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _editCar(
                                                    plate,
                                                    _brandController.text
                                                        .trim(),
                                                    _modelController.text
                                                        .trim(),
                                                  );
                                                },
                                                child: Text("Save"),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                ),
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
            Text("Modify a vehicle"),
            TextField(
              controller: _plateController,
              decoration: InputDecoration(labelText: "License Plate"),
            ),
            TextField(
              controller: _brandController,
              decoration: InputDecoration(labelText: "Brand"),
            ),
            TextField(
              controller: _modelController,
              decoration: InputDecoration(labelText: "Model"),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _addCar, child: Text("Modify Vehicle")),
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
