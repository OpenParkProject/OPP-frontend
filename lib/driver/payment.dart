import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../API/client.dart';
import 'package:dio/dio.dart';

class ParkingPaymentPage extends StatelessWidget {
  final int ticketId;
  final String plate;
  final DateTime startDate;
  final int durationMinutes;
  final double totalCost;

  const ParkingPaymentPage({
    required this.ticketId,
    required this.plate,
    required this.startDate,
    required this.durationMinutes,
    required this.totalCost,
    super.key,
  });

  Future<void> _payTicket(BuildContext context) async {
    try {
      await DioClient().setAuthToken();
      await DioClient().dio.post('/tickets/$ticketId/pay');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Ticket paid successfully")));
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      String msg = "❌ Payment failed.";
      if (e is DioError && e.response?.data is Map) {
        final data = e.response?.data;
        msg = data?['detail'] ?? data?['error'] ?? msg;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _skipPayment(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("⚠️ Ticket created but not paid. It's currently not valid."),
      backgroundColor: Colors.orange,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final endDate = startDate.add(Duration(minutes: durationMinutes));
    final fromFormatted = "${DateFormat.Hm().format(startDate)} – ${startDate.day}/${startDate.month}";
    final toFormatted = "${DateFormat.Hm().format(endDate)} – ${endDate.day}/${endDate.month}";

    return Scaffold(
      appBar: AppBar(title: Text("Checkout"), automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.credit_card, size: 48, color: Theme.of(context).colorScheme.primary),
                SizedBox(height: 20),
                Text("Confirm your parking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text("Plate: $plate", style: TextStyle(fontSize: 16)),
                Text("Zone: Default", style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text("From: $fromFormatted", style: TextStyle(fontSize: 14)),
                Text("To: $toFormatted", style: TextStyle(fontSize: 14)),
                SizedBox(height: 20),
                Divider(),
                Text("Total: €${totalCost.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => _payTicket(context),
                  icon: Icon(Icons.check_circle),
                  label: Text("Confirm and Pay by Card"),
                  style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
                ),
                SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _skipPayment(context),
                  icon: Icon(Icons.access_time),
                  label: Text("Pay later"),
                  style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}