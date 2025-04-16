import 'package:flutter/material.dart';
import 'check_parking.dart';

class ControllerHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hi, Controller")),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CheckParkingScreen()));
            },
            child: Text("1) Check parking"),
          ),
          ElevatedButton(onPressed: () {}, child: Text("2) Fines of today")),
          ElevatedButton(onPressed: () {}, child: Text("3) Chalked plates")),
        ],
      ),
    );
  }
}
