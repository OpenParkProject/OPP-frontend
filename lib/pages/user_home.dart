import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_tickets.dart';
import 'register_plate.dart';
import 'parking_zone_selection.dart';
import 'extend_ticket.dart';

class UserHomePage extends StatefulWidget {
  final String userEmail;

  const UserHomePage({super.key, required this.userEmail});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  List<Ticket> userTickets = [];

  @override
  void initState() {
    super.initState();
    _loadUserTickets();
  }

  Future<void> _loadUserTickets() async {
    await TicketDB.loadTickets();
    setState(() {
      userTickets = TicketDB.getTicketsForUser(widget.userEmail);
    });
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('HH:mm, dd/MM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Active Parkings")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              if (userTickets.isEmpty)
                Text("No active tickets found.", style: TextStyle(fontSize: 18))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: userTickets.length,
                    itemBuilder: (context, index) {
                      final t = userTickets[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text("${t.plate} – ${t.zone}"),
                          subtitle: Text(
                              "From: ${_formatDateTime(t.startTime)}\nTo: ${_formatDateTime(t.endTime)}\n€ ${t.amount.toStringAsFixed(2)}"),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ExtendTicketPage(ticket: t)),
                              );
                            },
                            child: Text("Extend"),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParkingZoneSelectionPage(), // new ticket flow
                    ),
                  );
                },
                icon: Icon(Icons.add),
                label: Text("New Parking"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterPlatePage(userEmail: widget.userEmail),
                    ),
                  );
                },
                child: Text("Manage My Vehicles"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
