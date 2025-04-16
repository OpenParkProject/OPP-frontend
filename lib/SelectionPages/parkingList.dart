import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plate_ocr/SelectionPages/plateEdit.dart';



class Parking {
  final String name;
  final String address;
  final int spots;
  final double hourlyRate;

  Parking({
    required this.name,
    required this.address,
    required this.spots,
    required this.hourlyRate,
  });
}

class ParkingListScreen extends StatefulWidget {
  const ParkingListScreen({super.key});

  @override
  _ParkingListScreenState createState() => _ParkingListScreenState();
}

class _ParkingListScreenState extends State<ParkingListScreen> {
  Position? _currentPosition;
  List<Parking> _nearbyParkings = [];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _loadMockParkings();
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  void _loadMockParkings() {
    _nearbyParkings = [
      Parking(name: 'A Square Parking Lot', address: 'No. 88 Pace', spots: 20, hourlyRate: 5.0),
      Parking(name: 'B Building Parking Lot', address: 'No. 77, Felicità', spots: 15, hourlyRate: 3.5),
      Parking(name: 'C Shopping Mall Parking Lot', address: 'No. 99, Felicità', spots: 30, hourlyRate: 6.0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Near Parking Lot')),
      body: Column(
        children: [
          if (_currentPosition != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                '当前位置：纬度 ${_currentPosition!.latitude}, 经度 ${_currentPosition!.longitude}',
                style: TextStyle(fontSize: 16),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Loading position...'),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _nearbyParkings.length,
              itemBuilder: (context, index) {
                final parking = _nearbyParkings[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Card(
                    elevation: 2,
                    child: ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(parking.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('€${parking.hourlyRate.toStringAsFixed(2)}/h', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                      children: [
                        ListTile(title: Text('Location: ${parking.address}')),
                        ListTile(title: Text('Rest Place: ${parking.spots}')),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => LicensePlateListPage(parking: parking)),
                              );
                            },
                            child: Text('Choose'),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/*
class PaymentScreen extends StatelessWidget {
  final Parking parking;

  PaymentScreen({required this.parking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('支付 ${parking.name}')),
      body: Center(
        child: Text('支付界面 - 每小时 ¥${parking.hourlyRate.toStringAsFixed(2)}'),
      ),
    );
  }
}
*/
