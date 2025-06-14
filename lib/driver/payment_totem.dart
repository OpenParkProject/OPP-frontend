import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import '../API/client.dart';
import 'card_payment.dart';
import 'manual_card_form.dart';

class ParkingPaymentTotemPage extends StatelessWidget {
  final int ticketId;
  final String plate;
  final DateTime startDate;
  final int durationMinutes;
  final double totalCost;
  final String? zoneName;

  const ParkingPaymentTotemPage({
    required this.ticketId,
    required this.plate,
    required this.startDate,
    required this.durationMinutes,
    required this.totalCost,
    this.zoneName,
    super.key,
  });

  Future<void> _payTicket(BuildContext context) async {
    try {
      await DioClient().setAuthToken();
      await DioClient().dio.post('/tickets/$ticketId/pay');
      final endDate = startDate.add(Duration(minutes: durationMinutes));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Ticket paid successfully"))
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Payment failed"))
      );
    }
  }

  void _startPaymentFlow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isRfidEnabled = prefs.getBool("rfid_enabled") ?? false;

    final useRfidFlow = isRfidEnabled;

    final page = useRfidFlow
        ? CardPaymentPage(onConfirmed: () => _payTicket(context))
        : ManualCardFormPage(onConfirmed: () => _payTicket(context));

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final endDate = startDate.add(Duration(minutes: durationMinutes));
    final from = DateFormat.Hm().format(startDate);
    final to = DateFormat.Hm().format(endDate);

    return Scaffold(
      appBar: AppBar(title: Text("Totem Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card, size: 60, color: Theme.of(context).colorScheme.primary),
            Text("Plate: $plate", style: TextStyle(fontSize: 18)),
            Text("Zone: ${zoneName ?? 'Unknown'}"),
            Text("From: $from"),
            Text("To: $to"),
            SizedBox(height: 20),
            Text("Total: €${totalCost.toStringAsFixed(2)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _startPaymentFlow(context),
              icon: Icon(Icons.credit_card),
              label: Text("Pay by Card"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
