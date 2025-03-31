import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plate_ocr/myDrawer.dart';
import 'settings.dart';


class ParkingPaymentPage extends StatefulWidget {
  const ParkingPaymentPage({super.key});

  @override
  _ParkingPaymentPageState createState() => _ParkingPaymentPageState();
}

class _ParkingPaymentPageState extends State<ParkingPaymentPage> {
  String selectedPaymentMethod = 'PayPal';

  final List<String> paymentMethods = ['PayPal', 'GooglePay', 'ApplePay','Satispay', 'Credit Card'];
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
      drawer: MyDrawer(),
      appBar: AppBar(title: const Text('Parking Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Parking Lot Location:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text(location, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.car_rental),
              title: const Text('Car Information:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Brand: Toyota', style: TextStyle(fontSize: 16)),
                  const Text('Model: Corolla', style: TextStyle(fontSize: 16)),
                  const Text('Plate Number: 粤A12345', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Parking Time:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: const Text('Parking time:2h', style: TextStyle(fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.price_check),
              title: const Text('Parking Price', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text('Fees payable:€20.00', style: const TextStyle(fontSize: 16, color: Colors.red)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payment Method:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: DropdownButton<String>(
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
            ),


            const Spacer(),
            const SizedBox(height: 290),
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
