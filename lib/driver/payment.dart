import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openpark/config.dart';
import '../API/client.dart';
import 'package:dio/dio.dart';

class ParkingPaymentPage extends StatelessWidget {
  final int ticketId;
  final String plate;
  final DateTime startDate;
  final int durationMinutes;
  final double totalCost;
  final bool allowPayLater;

  const ParkingPaymentPage({
    required this.ticketId,
    required this.plate,
    required this.startDate,
    required this.durationMinutes,
    required this.totalCost,
    this.allowPayLater = true,
    super.key,
  });

  Future<void> _payTicket(BuildContext context, String paymentMethod) async {
    try {
      await DioClient().setAuthToken();
      
      await DioClient().dio.post('/tickets/$ticketId/pay');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Ticket paid successfully with $paymentMethod"))
      );
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

  void _skipPayment(BuildContext context) async {
    try {
      await DioClient().setAuthToken();
      await DioClient().dio.delete('/tickets/$ticketId');

      Navigator.popUntil(context, (route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("🗑️ Ticket cancelled and deleted."),
        backgroundColor: Colors.red.shade400,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Failed to delete ticket."),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final endDate = startDate.add(Duration(minutes: durationMinutes));
    final fromFormatted = "${DateFormat.Hm().format(startDate)} – ${startDate.day}/${startDate.month}";
    final toFormatted = "${DateFormat.Hm().format(endDate)} – ${endDate.day}/${endDate.month}";

    return Scaffold(
      appBar: AppBar(
        title: Text("Checkout"),
        automaticallyImplyLeading: allowPayLater,
      ),
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
                
                // Payment options section
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 4.5,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _payTicket(context, "Card"),
                      icon: Icon(Icons.credit_card),
                      label: Text("Card"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _payTicket(context, "Google Pay"),
                      icon: Icon(Icons.android),
                      label: Text("Google Pay"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _payTicket(context, "Apple Pay"),
                      icon: Icon(Icons.apple),
                      label: Text("Apple Pay"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _payTicket(context, "Satispay"),
                      icon: Icon(Icons.qr_code),
                      label: Text("Satispay"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () {
                    if (allowPayLater) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("💤 Ticket created but not paid yet! Remember to pay it to make it valid."),
                      ));
                    } else {
                      _skipPayment(context);
                    }
                  },
                  icon: Icon(allowPayLater ? Icons.access_time : Icons.cancel),
                  label: Text(allowPayLater ? "Pay later" : "Cancel and delete ticket"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    foregroundColor: allowPayLater ? null : Colors.red,
                    side: allowPayLater ? null : BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}