import 'package:flutter/material.dart';
import '../db/db_zones.dart';
import 'parking_payment.dart';

class ParkingSummaryPage extends StatelessWidget {
  final ParkingZone zone;
  final double durationMinutes;
  final String plate;

  const ParkingSummaryPage({
    required this.zone,
    required this.durationMinutes,
    required this.plate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final total = (zone.hourlyRate / 60) * durationMinutes;
    final endTime = TimeOfDay.now().replacing(
      minute: (TimeOfDay.now().minute + durationMinutes.toInt()) % 60,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Parking Summary')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 48, color: Theme.of(context).colorScheme.primary),
              SizedBox(height: 20),
              Text("Zone: ${zone.name}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("Rate: €${zone.hourlyRate}/hr", style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              Text("Duration: ${durationMinutes.round()} minutes", style: TextStyle(fontSize: 16)),
              Text("Total: €${total.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 16),
              Text("Plate: $plate", style: TextStyle(fontSize: 16)),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParkingPaymentPage(
                        zone: zone,
                        duration: durationMinutes,
                        plate: plate,
                        totalCost: total,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.payment),
                label: Text("Pay Parking"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
