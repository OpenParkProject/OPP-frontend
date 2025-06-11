import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../API/client.dart';
import 'package:dio/dio.dart';

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

  Future<void> _payFine(BuildContext context) async {
    try {
      await DioClient().setAuthToken();
      await DioClient().dio.post('/fines/$fineId/pay');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Fine paid successfully")),
      );

      Navigator.pop(context, true); // torna indietro e aggiorna
    } catch (e) {
      String msg = "❌ Payment failed.";
      if (e is DioException && e.response?.data is Map) {
        final data = e.response?.data;
        msg = data?['detail'] ?? data?['error'] ?? msg;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text("Amount due:",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                Text("€${amount.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => _payFine(context),
                  icon: const Icon(Icons.payment),
                  label: const Text("Pay Now"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
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
