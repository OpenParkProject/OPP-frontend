import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExtendTicketPage extends StatefulWidget {
  final int ticketId;
  final String plate;
  final DateTime oldStart;
  final DateTime oldEnd;
  final double oldPrice;

  const ExtendTicketPage({
    required this.ticketId,
    required this.plate,
    required this.oldStart,
    required this.oldEnd,
    required this.oldPrice,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 20),
            Text("Plate: ${widget.plate}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text(
              "Original duration: ${_formatDuration(oldDuration)}",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Current end: ${DateFormat('dd/MM – HH:mm').format(widget.oldEnd)}",
            ),
            SizedBox(height: 20),

            // Selettore durata
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => _changeDuration(-60),
                  child: Text("-1h"),
                ),
                OutlinedButton(
                  onPressed: () => _changeDuration(-10),
                  child: Text("-10m"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "+${_formatDuration(extraMinutes)}",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _changeDuration(10),
                  child: Text("+10m"),
                ),
                OutlinedButton(
                  onPressed: () => _changeDuration(60),
                  child: Text("+1h"),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text("New end: ${DateFormat('dd/MM – HH:mm').format(newEnd)}"),
            SizedBox(height: 10),
            Text(
              "Additional cost: €${additionalCost.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 30),

            ElevatedButton.icon(
              icon: Icon(Icons.arrow_forward),
              label: Text("Add"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
