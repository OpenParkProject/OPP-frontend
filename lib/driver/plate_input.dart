import 'package:flutter/material.dart';
import 'create_ticket.dart';
import '../API/client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'zone_selection.dart';

class SimplePlateInputPage extends StatefulWidget {
  const SimplePlateInputPage({super.key});

  @override
  State<SimplePlateInputPage> createState() => _SimplePlateInputPageState();
}

class _SimplePlateInputPageState extends State<SimplePlateInputPage> {
  final TextEditingController _plateController = TextEditingController();
  String? _error;

  void _confirmPlate() async {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isEmpty || plate.length < 5) {
      setState(() => _error = "Please enter a valid license plate.");
      return;
    }

    setState(() => _error = null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      await DioClient().dio.post("/users/me/cars", data: {
        "plate": plate,
        "brand": "unknown",
        "model": "unknown",
      });
    } catch (e) {
      debugPrint("⚠️ Unable to register plate $plate: $e");
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final zoneId = prefs.getInt("selected_zone_id") ?? prefs.getInt("zone_id");

      if (zoneId == null) {
        Navigator.pop(context);
        setState(() => _error = "No zone selected.");
        return;
      }

      await DioClient().setAuthToken();
      final res = await DioClient().dio.get("/zones/$zoneId");
      final zone = ParkingZone.fromJson(res.data);

      Navigator.pop(context);

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
      Navigator.pop(context);
      debugPrint("❌ Failed to load zone: $e");
      setState(() => _error = "Error fetching zone.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enter License Plate")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _plateController,
              decoration: InputDecoration(
                labelText: "License Plate",
                border: OutlineInputBorder(),
                errorText: _error,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.check),
              label: Text("Confirm Plate"),
              onPressed: _confirmPlate,
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }
}
