import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'payment.dart';
import '../API/client.dart';

class ExtendTicketPage extends StatefulWidget {
  final int ticketId;
  final String plate;
  final DateTime oldStart;
  final DateTime oldEnd;
  final double oldPrice;
  final int zoneId;

  const ExtendTicketPage({
    required this.ticketId,
    required this.plate,
    required this.oldStart,
    required this.oldEnd,
    required this.oldPrice,
    required this.zoneId,
    super.key,
  });

  @override
  State<ExtendTicketPage> createState() => _ExtendTicketPageState();
}

class _ExtendTicketPageState extends State<ExtendTicketPage> {
  int extraMinutes = 30;
  final double pricePerMinute = 0.02;

  void _changeDuration(int delta) {
    setState(() {
      extraMinutes = (extraMinutes + delta).clamp(10, 720);
    });
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return "$minutes min";
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? "${h}h" : "${h}h ${m}m";
  }

  @override
  Widget build(BuildContext context) {
    final oldDuration = widget.oldEnd.difference(widget.oldStart).inMinutes;
    final newTotalDuration = oldDuration + extraMinutes;
    final newEnd = widget.oldStart.add(Duration(minutes: newTotalDuration));
    final additionalCost = extraMinutes * pricePerMinute;

    return Scaffold(
      appBar: AppBar(title: Text("Extend Ticket")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 15),
              Icon(Icons.timer_outlined, size: 48, color: Theme.of(context).primaryColor),
              SizedBox(height: 24),
              Text("Plate: ${widget.plate}", style: TextStyle(fontSize: 18)),
              SizedBox(height: 12),
              Text("Original duration: ${_formatDuration(oldDuration)}", textAlign: TextAlign.center),
              Text("Current end: ${DateFormat('dd/MM – HH:mm').format(widget.oldEnd)}", textAlign: TextAlign.center),
              SizedBox(height: 38),

              Text("Adjust extension:", style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),

              Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;

                  if (screenWidth >= 600) {
                    // SCHERMI LARGHI: tutto su una riga
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(onPressed: () => _changeDuration(-60), child: Text("-1h")),
                        SizedBox(width: 8),
                        OutlinedButton(onPressed: () => _changeDuration(-10), child: Text("-10m")),
                        SizedBox(width: 16),
                        Chip(
                          label: Text(
                            "+${_formatDuration(extraMinutes)}",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: StadiumBorder(side: BorderSide(color: Theme.of(context).primaryColor)),
                        ),
                        SizedBox(width: 16),
                        OutlinedButton(onPressed: () => _changeDuration(10), child: Text("+10m")),
                        SizedBox(width: 8),
                        OutlinedButton(onPressed: () => _changeDuration(60), child: Text("+1h")),
                      ],
                    );
                  } else {
                    // SCHERMI PICCOLI: layout verticale
                    return Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton(onPressed: () => _changeDuration(-60), child: Text("-1h")),
                            OutlinedButton(onPressed: () => _changeDuration(-10), child: Text("-10m")),
                          ],
                        ),
                        SizedBox(height: 12),
                        Chip(
                          label: Text(
                            "+${_formatDuration(extraMinutes)}",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: StadiumBorder(side: BorderSide(color: Theme.of(context).primaryColor)),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton(onPressed: () => _changeDuration(10), child: Text("+10m")),
                            OutlinedButton(onPressed: () => _changeDuration(60), child: Text("+1h")),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),

              SizedBox(height: 10),
              Text("New end: ${DateFormat('dd/MM – HH:mm').format(newEnd)}", textAlign: TextAlign.center),
              SizedBox(height: 6),
              Text(
                "Additional cost: €${additionalCost.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),

              ElevatedButton.icon(
                icon: Icon(Icons.arrow_forward),
                label: Text("Proceed to Payment"),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
                onPressed: () async {
                  final newStart = widget.oldEnd.toUtc();
                  final newDuration = extraMinutes;
                  final cost = newDuration * pricePerMinute;

                  try {
                    await DioClient().setAuthToken();
                    final response = await DioClient().dio.post(
                      "/zones/${widget.zoneId}/tickets",
                      data: {
                        "plate": widget.plate,
                        "start_date": newStart.toIso8601String(),
                        "duration": newDuration,
                      },
                    );

                    final newTicketId = response.data['id'];

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParkingPaymentPage(
                          ticketId: newTicketId,
                          plate: widget.plate,
                          startDate: widget.oldEnd,
                          durationMinutes: newDuration,
                          totalCost: cost,
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("❌ Failed to create extension ticket")),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}