import 'package:flutter/material.dart';

class ReceiptPage extends StatelessWidget {
  final String carNumber;
  final String duration;
  final int fee;

  const ReceiptPage({super.key,
    required this.carNumber,
    required this.duration,
    required this.fee,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ticket')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ticket', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Divider(height: 30),
                _buildRow('Plate Number:', carNumber),
                _buildRow('Parking Duration:', duration),
                _buildRow('Fees:', '$fee €'),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('return'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
