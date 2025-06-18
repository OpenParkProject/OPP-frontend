import 'package:flutter/material.dart';
import '../API/client.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'create_ticket.dart';
import '../admin/zone_status.dart';

class MyCarsPage extends StatefulWidget {
  final void Function(String)? onPlateSelected;

  const MyCarsPage({this.onPlateSelected, super.key});

  @override
  State<MyCarsPage> createState() => _MyCarsPageState();
}

class _MyCarsPageState extends State<MyCarsPage> {
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _brandController = TextEditingController();

  List<Map<String, String>> userPlates = [];
  bool loadingPlates = true;
  String? _feedbackMessage;
  Set<String> disabledPlates = {};


  @override
  void initState() {
    super.initState();
    _fetchPlates();
  }

  Future<void> _fetchPlates() async {
    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      // 1. Fetch plates
      final carsRes = await dio.get("/users/me/cars");
      final fetchedCars = (carsRes.data as List)
          .map((car) => {
                "plate": car['plate']?.toString().toUpperCase().trim() ?? '',
                "model": car['model']?.toString() ?? '',
                "brand": car['brand']?.toString() ?? ''
              })
          .toList();


      // 2. Fetch active tickets (valid_only = true)
      final ticketsRes = await dio.get("/users/me/tickets", queryParameters: {
        "valid_only": "true", // <-- must be string!
      });

      final List<dynamic> ticketList = ticketsRes.data;

      final Set<String> activePlates = ticketList
          .where((t) => t['paid'] == true)
          .map((t) => t['plate'].toString().toUpperCase().trim())
          .toSet();


      setState(() {
        userPlates = fetchedCars;
        disabledPlates = activePlates;
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
        "/users/me/cars",
        data: {
          "plate": plate,
          "brand": brand,
          "model": model,
        },
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

  Future<void> _handlePlateSelection(String plate) async {
    final prefs = await SharedPreferences.getInstance();
    final zoneId = prefs.getInt("selected_zone_id") ?? prefs.getInt("zone_id");

    if (zoneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No zone selected.")));
      return;
    }

    try {
      await DioClient().setAuthToken();
      final res = await DioClient().dio.get("/zones/$zoneId");
      final zone = ParkingZone.fromJson(res.data);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SelectDurationPage(
            plate: plate,
            selectedZone: zone,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load zone info.")));
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
            if (loadingPlates)
              CircularProgressIndicator()
            else if (userPlates.isNotEmpty) ...[
              Text("Registered Plates:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...userPlates.map((car) {
                final plate = car['plate'] ?? '';
                final label = "${car['brand'] ?? ''} ${car['model'] ?? ''}".trim();
                final isDisabled = disabledPlates.contains(plate);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: Icon(Icons.directions_car),
                    title: Text(
                      plate,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Text(label + (isDisabled ? " – There is already an active ticket for this car" : "")),
                    trailing: isDisabled
                        ? Icon(Icons.block, color: Colors.red)
                        : Icon(Icons.arrow_forward),
                    tileColor: isDisabled ? Colors.grey.shade200 : null,
                    onTap: isDisabled ? null : () => _handlePlateSelection(plate),
                  ),
                );
              }),
              Divider(),
            ],
            Text("Add a new vehicle"),
            TextField(controller: _plateController, decoration: InputDecoration(labelText: "License Plate")),
            TextField(controller: _brandController, decoration: InputDecoration(labelText: "Brand")),
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
