import 'package:flutter/material.dart';

class ExtendParking extends StatefulWidget {
  @override
  State<ExtendParking> createState() => _ExtendParkingState();
}

class _ExtendParkingState extends State<ExtendParking> {
  double _extraMinutes = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Estendi Parcheggio")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Durata attuale: fino alle 16:30"),
            SizedBox(height: 20),
            Text("Estensione: ${_extraMinutes.round()} minuti"),
            Slider(
              value: _extraMinutes,
              min: 15,
              max: 180,
              divisions: 11,
              label: "${_extraMinutes.round()} min",
              onChanged: (value) {
                setState(() {
                  _extraMinutes = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Parcheggio esteso di ${_extraMinutes.round()} minuti!")));
                Navigator.pop(context);
              },
              child: Text("Conferma estensione"),
            )
          ],
        ),
      ),
    );
  }
}
