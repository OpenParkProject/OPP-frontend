import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io' show Platform;
import '../API/client.dart';
import 'card_payment.dart';
import 'manual_card_form.dart';

class FinePaymentPage extends StatelessWidget {
  final int fineId;
  final double amount;
  final String plate;

  const FinePaymentPage({
    super.key,
    required this.fineId,
    required this.amount,
    required this.plate,
  });

  Future<void> _payFine(BuildContext context, String method) async {
    try {
      await DioClient().setAuthToken();
      await DioClient().dio.post('/fines/$fineId/pay');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Fine paid successfully with $method")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      String msg = "❌ Payment failed.";
      if (e is DioException && e.response?.data is Map) {
        final data = e.response?.data;
        msg = data?['detail'] ?? data?['error'] ?? msg;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _buildPaymentButton(BuildContext context, String label, IconData icon, Color color, String method) {
    return ElevatedButton.icon(
      onPressed: () {
        if (method == "Card") {
          final page = Platform.isLinux
              ? CardPaymentPage(onConfirmed: () => _payFine(context, method))
              : ManualCardFormPage(onConfirmed: () => _payFine(context, method));
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        } else {
          _payFine(context, method);
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

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _buildPaymentButton(context, "Card", Icons.credit_card, Theme.of(context).colorScheme.primary, "Card"),
      _buildPaymentButton(context, "Google Pay", Icons.android, Colors.black, "Google Pay"),
      _buildPaymentButton(context, "Apple Pay", Icons.apple, Colors.black, "Apple Pay"),
      _buildPaymentButton(context, "Satispay", Icons.qr_code, Colors.red, "Satispay"),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Fine Payment")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Icon(Icons.gavel, size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 20),
                const Text(
                  "Confirm your fine payment",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text("Plate: $plate", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                Text("Amount due:", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                Text("€${amount.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Text("Choose your payment method:"),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    final spacing = isWide ? 12.0 : 8.0;
                    final buttonWidth = isWide ? 180.0 : double.infinity;

                    if (isWide) {
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        alignment: WrapAlignment.center,
                        children: buttons.map((b) => SizedBox(width: buttonWidth, height: 48, child: b)).toList(),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
