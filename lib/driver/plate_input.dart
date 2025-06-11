import 'package:flutter/material.dart';
import 'create_ticket.dart';
import 'zone_selection.dart';
import '../API/client.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimplePlateInputPage extends StatefulWidget {
  final ParkingZone selectedZone;

  const SimplePlateInputPage({required this.selectedZone, super.key});

  @override
  State<SimplePlateInputPage> createState() => _SimplePlateInputPageState();
}

class _SimplePlateInputPageState extends State<SimplePlateInputPage> {
  final TextEditingController _plateController = TextEditingController();
  String? _error;

  Future<void> loginOrRegisterGuest() async {
    final dio = DioClient().dio;

    try {
      // 1. Prova login
      final response = await dio.post('/login', data: {
        'username': 'guest',
        'password': 'guest123',
      });

      final token = response.data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      DioClient().dio.options.headers['Authorization'] = 'Bearer $token';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        // 2. Utente non esistente → registrazione
        final registerResp = await dio.post('/register', data: {
          "name": "Guest",
          "surname": "User",
          "username": "guest",
          "email": "guest@openpark.app",
          "password": "guest123",
          "role": "driver",
        });

        final loginResp = await dio.post('/login', data: {
          'username': 'guest',
          'password': 'guest123',
        });

        final token = loginResp.data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        DioClient().dio.options.headers['Authorization'] = 'Bearer $token';
      } else {
        throw Exception("Login error: ${e.response?.data ?? e.message}");
      }
    }
  }

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
      await loginOrRegisterGuest();

      try {
        await DioClient().dio.post("/users/me/cars", data: {
          "plate": plate,
          "brand": "unknown",
          "model": "unknown",
        });
      } catch (e) {
        debugPrint("⚠️ Unable to register plate $plate: $e");
      }

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SelectDurationPage(
            plate: plate,
            selectedZone: widget.selectedZone,
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      setState(() => _error = "❌ Login or registration failed.");
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
