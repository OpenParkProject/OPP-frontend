import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_tickets.dart';

class ExtendTicketPage extends StatefulWidget {
  final Ticket ticket;

  const ExtendTicketPage({super.key, required this.ticket});

  @override
  State<ExtendTicketPage> createState() => _ExtendTicketPageState();
}

class _ExtendTicketPageState extends State<ExtendTicketPage> {
  double extraMinutes = 30;

  String formatDuration(double minutes) {
    if (minutes < 60) return "${minutes.round()} min";
    return "${(minutes / 60).toStringAsFixed(1)} h";
  }

  double calculateExtraCost() {
    return (widget.ticket.amount / widget.ticket.ticketDuration().inMinutes) * extraMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final extraCost = calculateExtraCost();
    final newEnd = widget.ticket.endTime.add(Duration(minutes: extraMinutes.round()));
    final formatter = DateFormat('HH:mm, dd/MM');

    return Scaffold(
      appBar: AppBar(title: Text("Extend Parking")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Vehicle: ${widget.ticket.plate}", style: TextStyle(fontSize: 18)),
              Text("Zone: ${widget.ticket.zone}"),
              SizedBox(height: 20),
              Text("Current ends at: ${formatter.format(widget.ticket.endTime)}"),
              Text("Extended to: ${formatter.format(newEnd)}"),
              SizedBox(height: 20),
              Text("Extend by: ${formatDuration(extraMinutes)}"),
              Slider(
                value: extraMinutes,
                min: 15,
                max: 180,
                divisions: 33,
                label: formatDuration(extraMinutes),
                onChanged: (val) {
                  setState(() {
                    extraMinutes = val;
                  });
                },
              ),
              SizedBox(height: 20),
              Text("Extra cost: €${extraCost.toStringAsFixed(2)}"),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final extended = Ticket(
                    email: widget.ticket.email,
                    plate: widget.ticket.plate,
                    zone: widget.ticket.zone,
                    hourlyRate: widget.ticket.hourlyRate,
                    startTime: widget.ticket.startTime,
                    endTime: newEnd,
                    amount: widget.ticket.amount + extraCost,
                  );
                  await TicketDB.updateTicket(widget.ticket, extended);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Parking extended successfully!")));
                },
                icon: Icon(Icons.timer),
                label: Text("Confirm Extension"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
