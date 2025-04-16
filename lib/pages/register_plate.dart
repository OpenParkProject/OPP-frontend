import 'package:flutter/material.dart';
import '../db/db_users.dart';

class RegisterPlatePage extends StatefulWidget {
  final String userEmail;
  const RegisterPlatePage({super.key, required this.userEmail});

  @override
  State<RegisterPlatePage> createState() => _RegisterPlatePageState();
}

class _RegisterPlatePageState extends State<RegisterPlatePage> {
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final db = MockDB();
    final userPlates = db.getUserPlates(widget.userEmail);

    return Scaffold(
      appBar: AppBar(title: Text("My Vehicles")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (userPlates.isNotEmpty) ...[
              Text("Registered Plates:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...userPlates.map((plate) => ListTile(
                    title: Text(plate),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        db.removePlate(widget.userEmail, plate);
                        setState(() {});
                      },
                    ),
                  )),
              Divider(),
            ],
            Text("Add a new vehicle"),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Vehicle Name")),
            TextField(controller: _plateController, decoration: InputDecoration(labelText: "License Plate")),
            TextField(controller: _modelController, decoration: InputDecoration(labelText: "Model")),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_plateController.text.isNotEmpty) {
                  db.addPlate(widget.userEmail, _plateController.text.trim());
                  _plateController.clear();
                  _nameController.clear();
                  _modelController.clear();
                  setState(() {});
                }
              },
              child: Text("Add Vehicle"),
            ),
          ],
        ),
      ),
    );
  }
}

class Vehicle {
  final String name;
  final String plate;
  final String model;

  Vehicle({required this.name, required this.plate, required this.model});

  List<String> toCsvRow(String email) => [email, plate, name, model];

  static Vehicle fromCsv(List<String> row) =>
      Vehicle(plate: row[1], name: row[2], model: row[3]);
}
