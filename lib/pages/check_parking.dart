import 'package:flutter/material.dart';
import 'parking_status.dart';

class CheckParkingScreen extends StatelessWidget {
  final TextEditingController _plateController = TextEditingController(text: "AB123CD");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OCR / Plate Check")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recognized plate (editable):"),
            TextField(controller: _plateController),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ParkingStatusScreen(paid: true)));
              },
              child: Text("Check Plate"),
            )
          ],
        ),
      ),
    );
  }
}
