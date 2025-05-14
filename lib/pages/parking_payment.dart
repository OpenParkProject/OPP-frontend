import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_zones.dart';
import '../db/db_tickets.dart';

class ParkingPaymentPage extends StatelessWidget {
  final ParkingZone zone;
  final double duration;
  final String plate;
  final double totalCost;
  final String? userEmail;

  const ParkingPaymentPage({
    super.key,
    required this.zone,
    required this.duration,
    required this.plate,
    required this.totalCost,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final end = now.replacing(minute: (now.minute + duration.toInt()) % 60);
    final date = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text("Checkout")),
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
                Text("Zone: ${zone.name}", style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text("From: ${now.format(context)} – ${date.day}/${date.month}", style: TextStyle(fontSize: 14)),
                Text("To: ${end.format(context)} – ${date.day}/${date.month}", style: TextStyle(fontSize: 14)),
                SizedBox(height: 20),
                Divider(),
                Text("Total: €${(totalCost * 1.0825).toStringAsFixed(2)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final ticket = Ticket(
                      email: userEmail ?? "",
                      plate: plate,
                      zone: zone.name,
                      hourlyRate: zone.hourlyRate,
                      startTime: now,
                      endTime: now.add(Duration(minutes: duration.round())),
                      amount: totalCost,
                    );

                    await TicketDB.saveTicket(ticket);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Payment confirmed ✅")),
                    );
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: Icon(Icons.check_circle),
                  label: Text("Confirm and Pay by Card"),
                  style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
                ),
                SizedBox(height: 10),
                Text("or use", style: TextStyle(color: Colors.grey)),
                SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: Icon(Icons.paypal),
                      label: Text("PayPal"),
                      onPressed: () {},
                    ),
                    OutlinedButton.icon(
                      icon: Icon(Icons.apple),
                      label: Text("Apple Pay"),
                      onPressed: () {},
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
