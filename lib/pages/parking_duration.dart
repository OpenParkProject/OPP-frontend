import 'package:flutter/material.dart';
import '../db/db_zones.dart';
import '../db/db_users.dart';
import 'parking_submit_ticket.dart';

class ParkingDurationPage extends StatefulWidget {
  final ParkingZone zone;
  final String? userEmail;

  ParkingDurationPage({required this.zone, this.userEmail});

  @override
  State<ParkingDurationPage> createState() => _ParkingDurationPageState();
}

class _ParkingDurationPageState extends State<ParkingDurationPage> {
  double durationInMinutes = 30;
  String? selectedPlate;

  @override
  Widget build(BuildContext context) {
    double totalCost = (widget.zone.hourlyRate / 60) * durationInMinutes;
    final db = MockDB();

    List<String> plates = widget.userEmail != null
        ? db.getUserPlates(widget.userEmail!)
        : [];

    return Scaffold(
      appBar: AppBar(title: Text('Parking Duration')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Zone: ${widget.zone.name}"),
            Text("Rate: €${widget.zone.hourlyRate}/hr"),
            SizedBox(height: 20),
            Text("Duration: ${durationInMinutes.round()} minutes"),
            Slider(
              min: 15,
              max: 180,
              divisions: 11,
              value: durationInMinutes,
              label: "${durationInMinutes.round()} min",
              onChanged: (val) {
                setState(() {
                  durationInMinutes = val;
                });
              },
            ),
            Text("Total: €${totalCost.toStringAsFixed(2)}"),
            SizedBox(height: 20),
            if (plates.isNotEmpty) ...[
              DropdownButton<String>(
                value: selectedPlate,
                hint: Text("Select Vehicle"),
                isExpanded: true,
                items: plates
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPlate = value;
                  });
                },
              ),
            ] else ...[
              TextField(
                onChanged: (val) => selectedPlate = val.toUpperCase(),
                decoration: InputDecoration(labelText: "License Plate"),
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (selectedPlate == null || selectedPlate!.isEmpty) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParkingSubmitTicketPage(
                      plate: selectedPlate!, // assicurati che non sia null
                      duration: durationInMinutes.toInt(), // usa il valore già presente
                      startDate: DateTime.now(),
                    ),
                  ),
                );
              },
              child: Text("Proceed to Checkout"),
            )
          ],
        ),
      ),
    );
  }
}
