import 'package:flutter/material.dart';
import 'receipt.dart'; // 引入票据页面

class ParkingPage extends StatefulWidget {
  @override
  _ParkingPageState createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  final String carNumber = "粤A12345"; // 车辆信息（可替换为动态识别结果）

  String? selectedDuration;
  int parkingFee = 0;

  final Map<String, int> durationOptions = {
    '30分钟': 2,
    '1小时': 4,
    '2小时': 8,
    '3小时': 12,
    '全天': 20,
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
        SnackBar(content: Text('请先选择停车时间')),
      );
      return;
    }

    // 模拟支付成功后跳转
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
      appBar: AppBar(title: Text('选择停车时间')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              hint: Text('请选择停车时间'),
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
              '停车费用：${parkingFee}元',
              style: TextStyle(fontSize: 18),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _onPay,
              child: Text('支付并生成票据'),
            ),
          ],
        ),
      ),
    );
  }
}
