import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPlatePage extends StatefulWidget {
  final String userEmail;
  const RegisterPlatePage({super.key, required this.userEmail});

  @override
  State<RegisterPlatePage> createState() => _RegisterPlatePageState();
}

class _RegisterPlatePageState extends State<RegisterPlatePage> {
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _brandController = TextEditingController();

  List<String> userPlates = [];
  String? _feedbackMessage;

  Future<void> _addCar() async {
    final plate = _plateController.text.trim().toUpperCase();
    final model = _modelController.text.trim();
    final brand = _brandController.text.trim();

    if (plate.isEmpty || brand.isEmpty || model.isEmpty) {
      setState(() => _feedbackMessage = "❗ Please fill all fields.");
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final dio = Dio(BaseOptions(baseUrl: "http://openpark.com/api/v1"));

      await dio.post(
        "/users/me/cars",
        data: {
          "plate": plate,
          "brand": brand,
          "model": model,
        },
        options: Options(headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        }),
      );

      setState(() {
        userPlates.add(plate);
        _feedbackMessage = "✅ Vehicle $plate registered successfully.";
        _plateController.clear();
        _brandController.clear();
        _modelController.clear();
      });
    } catch (e) {
      String msg = "❌ Failed to register vehicle.";
      if (e is DioException && e.response?.data is Map) {
        final data = e.response?.data;
        msg = "❌ ${data?['error'] ?? data?['detail'] ?? 'Unknown error'}";
      }
      setState(() => _feedbackMessage = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Vehicles")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (userPlates.isNotEmpty) ...[
              Text("Registered Plates:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...userPlates.map((plate) => ListTile(title: Text(plate))),
              Divider(),
            ],
            Text("Add a new vehicle"),
            TextField(controller: _brandController, decoration: InputDecoration(labelText: "Brand")),
            TextField(controller: _plateController, decoration: InputDecoration(labelText: "License Plate")),
            TextField(controller: _modelController, decoration: InputDecoration(labelText: "Model")),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addCar,
              child: Text("Add Vehicle"),
            ),
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