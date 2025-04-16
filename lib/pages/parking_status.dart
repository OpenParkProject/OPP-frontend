import 'package:flutter/material.dart';

class ParkingStatusScreen extends StatelessWidget {
  final bool paid;
  ParkingStatusScreen({required this.paid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Parking Status")),
      body: Center(
        child: paid
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("✅ Parking Paid"),
                  Text("Expires at: 16:30"),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Go Back"),
                  )
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("❌ Not Paid"),
                  Text("Expired since 8 minutes"),
                  ElevatedButton(onPressed: () {}, child: Text("Emit Fine")),
                ],
              ),
      ),
    );
  }
}
