import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../API/client.dart';
import 'package:dio/dio.dart';
import 'dart:io' show Platform;
import 'card_payment.dart';
import 'manual_card_form.dart';

const bool debugCard = false;

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

  Widget _buildPaymentButton(BuildContext context, String label, IconData icon, Color color, String method) {
    return ElevatedButton.icon(
      onPressed: () {
        if (method == "Card") {
          final page = Platform.isLinux || debugCard
              ? CardPaymentPage(onConfirmed: () => _payTicket(context, method))
              : ManualCardFormPage(onConfirmed: () => _payTicket(context, method));
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        } else {
          _payTicket(context, method);
        }
      },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

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
        automaticallyImplyLeading: false,
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
                Text("Choose your payment method: "),
                SizedBox(height: 5),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth > 600;
                    final buttonWidth = isWideScreen ? 180.0 : double.infinity;
                    final spacing = isWideScreen ? 12.0 : 8.0;

                    final buttons = [
                      _buildPaymentButton(context, "Card", Icons.credit_card, Theme.of(context).colorScheme.primary, "Card"),
                      _buildPaymentButton(context, "Google Pay", Icons.android, Colors.black, "Google Pay"),
                      _buildPaymentButton(context, "Apple Pay", Icons.apple, Colors.black, "Apple Pay"),
                      _buildPaymentButton(context, "Satispay", Icons.qr_code, Colors.red, "Satispay"),
                    ];

                    if (isWideScreen) {
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        alignment: WrapAlignment.center,
                        children: buttons
                            .map((b) => SizedBox(width: buttonWidth, height: 48, child: b))
                            .toList(),
                      );
                    } else {
                      return Column(
                        children: buttons
                            .map((b) => Padding(
                                  padding: EdgeInsets.symmetric(vertical: spacing / 2),
                                  child: SizedBox(width: double.infinity, height: 48, child: b),
                                ))
                            .toList(),
                      );
                    }
                  },
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