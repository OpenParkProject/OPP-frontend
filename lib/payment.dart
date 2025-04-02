import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking Payment',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ParkingPaymentPage(),
    );
  }
}

class ParkingPaymentPage extends StatefulWidget {
  const ParkingPaymentPage({super.key});

  @override
  _ParkingPaymentPageState createState() => _ParkingPaymentPageState();
}

class _ParkingPaymentPageState extends State<ParkingPaymentPage> {
  String selectedPaymentMethod = 'PayPal';
  final List<String> paymentMethods = ['PayPal', 'GooglePay', 'Credit Card', 'Satispay'];
  String location = 'Getting location...';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        location = 'Location services not enabled';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          location = 'Location permission denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        location = 'Location permission permanently denied';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      location = 'latitude: ${position.latitude}, longitude: ${position.longitude}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parking Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Parking Lot Location:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(location, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            const Text('License plate information:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('CD5678', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            const Text('Parking Times and Prices:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Parking time:2h', style: TextStyle(fontSize: 16)),
            const Text('Fees payable:€20.00', style: TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 16),

            const Text('Select payment method:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedPaymentMethod,
              items: paymentMethods.map((String method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedPaymentMethod = newValue!;
                });
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payment successful: $selectedPaymentMethod')),
                  );
                },
                child: const Text('Payment', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
