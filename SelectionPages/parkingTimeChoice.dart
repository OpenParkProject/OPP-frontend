import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plate_ocr/SelectionPages/parkingList.dart';
import 'package:plate_ocr/SelectionPages/payment_selection.dart';



class ParkingTimeScreen extends StatefulWidget {
  final Parking parking;
  final String plateNumber;
  const ParkingTimeScreen({super.key, required this.parking, required this.plateNumber});
  _ParkingTimeScreenState createState() => _ParkingTimeScreenState();
}

class _ParkingTimeScreenState extends State<ParkingTimeScreen> {
  //final List<String> licensePlates = ['浙A12345', '浙B67890', '沪C54321'];
  final List<int> parkingDurations = [60, 90, 120, 150, 180, 210, 240]; // 单位：分钟

  String? selectedPlate;
  int? selectedDuration;
  DateTime currentTime = DateTime.now();

  String formatTime(DateTime time) {
    return DateFormat('yyyy-MM-dd HH:mm').format(time);
  }

  DateTime get endTime {
    if (selectedDuration != null) {
      return currentTime.add(Duration(minutes: selectedDuration!));
    }
    return currentTime;
  }

  void confirm() {
    if (selectedDuration != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            plate: widget.plateNumber,
            startTime: currentTime,
            endTime: endTime,
            fees: (selectedDuration! * widget.parking.hourlyRate)/60,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a parking duration.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    currentTime = DateTime.now(); // 每次 build 时更新当前时间

    return Scaffold(
      appBar: AppBar(title: Text('Parking Screen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /*DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Choose License Plate'),
              value: selectedPlate,
              items: licensePlates
                  .map((plate) => DropdownMenuItem(
                value: plate,
                child: Text(plate),
              ))
                  .toList(),
              onChanged: (value) => setState(() => selectedPlate = value),
            ),
            SizedBox(height: 16),*/
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'Choose Parking Duration min'),
              value: selectedDuration,
              items: parkingDurations
                  .map((duration) => DropdownMenuItem(
                value: duration,
                child: Text('$duration min'),
              ))
                  .toList(),
              onChanged: (value) => setState(() => selectedDuration = value),
            ),
            SizedBox(height: 16),
            Text('Current Time: ${formatTime(currentTime)}'),
            SizedBox(height: 8),
            Text('End Time: ${formatTime(endTime)}'),
            Spacer(),
            ElevatedButton(
              onPressed: confirm,
              child: Text('Pay'),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  final String plate;
  final DateTime startTime;
  final DateTime endTime;
  final double fees;

  const PaymentScreen({super.key,
    required this.plate,
    required this.startTime,
    required this.endTime, required this.fees,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plate Number: $plate'),
            SizedBox(height: 8),
            Text('Start Time: ${DateFormat('yyyy-MM-dd HH:mm').format(startTime)}'),
            SizedBox(height: 8),
            Text('End Time: ${DateFormat('yyyy-MM-dd HH:mm').format(endTime)}'),
            SizedBox(height: 32),
            Text('Total Fees: ${fees}€'),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // 此处可添加支付逻辑
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentSelectionPage()),
                  );
                  /*ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('支付成功！')),);*/

                },
                child: Text('Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
