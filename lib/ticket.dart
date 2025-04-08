import 'package:flutter/material.dart';
import 'package:plate_ocr/payment_selection.dart';
import 'receipt.dart'; // 引入票据页面

class ParkingPage extends StatefulWidget {
  @override
  _ParkingPageState createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  final String carNumber = "BA12345"; // 车辆信息（可替换为动态识别结果）

  String? selectedDuration;
  int parkingFee = 0;

  final Map<String, int> durationOptions = {
    '1h': 4,
    '2h': 8,
    '3h': 12,
    'One Day': 20,
  };

  void _onDurationChanged(String? newValue) {
    setState(() {
      selectedDuration = newValue;
      parkingFee = durationOptions[newValue]!;
    });
  }

  void _onPay() {
    if (selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Choose your parking duration')),
      );
      return;
    }

    // 模拟支付成功后跳转
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSelectionPage(),
      ),
    );
  }

  void _onPayed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptPage(
          carNumber: carNumber,
          duration: selectedDuration!,
          fee: parkingFee,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose your parking duration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              hint: Text('Choose your parking duration'),
              value: selectedDuration,
              isExpanded: true,
              items: durationOptions.keys.map((String duration) {
                return DropdownMenuItem<String>(
                  value: duration,
                  child: Text(duration),
                );
              }).toList(),
              onChanged: _onDurationChanged,
            ),
            SizedBox(height: 20),
            Text(
              'Parking fees：${parkingFee}€',
              style: TextStyle(fontSize: 18),
            ),
            ElevatedButton(onPressed: _onPayed, child: Text("Check your ticket")),
            Spacer(),
            ElevatedButton(
              onPressed: _onPay,
              child: Text('Pay and get a receipt'),
            ),
          ],
        ),
      ),
    );
  }
}
