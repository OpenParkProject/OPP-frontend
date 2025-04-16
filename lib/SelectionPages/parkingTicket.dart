import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(ParkingTicketApp());
}

class ParkingTicketApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking Tickets',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ParkingTicketPage(),
    );
  }
}

class ParkingTicket {
  final String licensePlate;
  final String parkingLot;
  final DateTime startTime;
  DateTime endTime;
  bool isExpanded;

  ParkingTicket({
    required this.licensePlate,
    required this.parkingLot,
    required this.startTime,
    required this.endTime,
    this.isExpanded = false,
  });

  bool get isExpired => DateTime.now().isAfter(endTime);
}

class ParkingTicketPage extends StatefulWidget {
  @override
  _ParkingTicketPageState createState() => _ParkingTicketPageState();
}

class _ParkingTicketPageState extends State<ParkingTicketPage> {
  List<ParkingTicket> tickets = [];

  void _addTicket() {
    final now = DateTime.now();
    final ticket = ParkingTicket(
      licensePlate: "ABC-${1000 + tickets.length}",
      parkingLot: "P${tickets.length + 1}号停车场",
      startTime: now,
      endTime: now.add(Duration(hours: 2)),
    );
    setState(() {
      tickets.add(ticket);
    });
  }

  void _extendTicket(ParkingTicket ticket) {
    setState(() {
      ticket.endTime = ticket.endTime.add(Duration(hours: 1));
    });
  }

  String formatTime(DateTime time) {
    return DateFormat('yyyy-MM-dd HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的停车票'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addTicket,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: InkWell(
              onTap: () {
                setState(() {
                  ticket.isExpanded = !ticket.isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plate Number: ${ticket.licensePlate}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (ticket.isExpanded) ...[
                      SizedBox(height: 4),
                      Text('停车场: ${ticket.parkingLot}'),
                      Text('Start Time: ${formatTime(ticket.startTime)}'),
                      Text('End Time: ${formatTime(ticket.endTime)}'),
                      Text(
                        'State: ${ticket.isExpired ? "Expired" : "Usable"}',
                        style: TextStyle(
                          color: ticket.isExpired ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _extendTicket(ticket),
                        child: Text('Extend 1h'),
                      ),
                    ] else ...[
                      SizedBox(height: 4),
                      Text(
                        'State: ${ticket.isExpired ? "Expired" : "Usable"}',
                        style: TextStyle(
                          color: ticket.isExpired ? Colors.red : Colors.green,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
