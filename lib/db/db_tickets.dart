import 'dart:io';
import 'package:intl/intl.dart';

class Ticket {
  final String email;       // può essere ""
  final String plate;
  final String zone;
  final double hourlyRate;
  final DateTime startTime;
  final DateTime endTime;
  double amount;

  Ticket({
    required this.email,
    required this.plate,
    required this.zone,
    required this.hourlyRate,
    required this.startTime,
    required this.endTime,
    required this.amount,
  });

  List<String> toCsvRow() => [
    email,
    plate,
    zone,
    hourlyRate.toStringAsFixed(2),
    startTime.toIso8601String(),
    endTime.toIso8601String(),
    amount.toStringAsFixed(2),
  ];

  static Ticket fromCsv(List<String> row) {
    return Ticket(
      email: row[0],
      plate: row[1],
      zone: row[2],
      hourlyRate: double.parse(row[3]),
      startTime: DateTime.parse(row[4]),
      endTime: DateTime.parse(row[5]),
      amount: double.parse(row[6]),
    );
  }
}

class TicketDB {
  static final String path = 'assets/data/db_tickets.csv';
  static final List<Ticket> _tickets = [];

  static Future<void> loadTickets() async {
    final file = File(path);
    if (!await file.exists()) return;

    final lines = await file.readAsLines();
    _tickets.clear();
    for (var line in lines.skip(1)) {
      final parts = line.split(',');
      if (parts.length == 6) {
        _tickets.add(Ticket.fromCsv(parts));
      }
    }
  }

  static Future<void> saveTicket(Ticket ticket) async {
    final file = File(path);
    if (!await file.exists()) {
      await file.writeAsString('email,plate,zone,hourly_rate,start_time,end_time,amount\n');
    }
    final line = ticket.toCsvRow().join(',') + '\n';
    await file.writeAsString(line, mode: FileMode.append);
    _tickets.add(ticket);
  }

  static List<Ticket> getTicketsForUser(String email) {
    return _tickets.where((t) => t.email == email).toList();
  }

  static Future<void> extendTicket(Ticket ticket, Duration extraTime, double extraAmount) async {
    ticket.endTime.add(extraTime);
    ticket.amount += extraAmount;
    await _rewriteFile(); // Optional: rebuild whole CSV
  }

  static Future<void> _rewriteFile() async {
    final file = File(path);
    final buffer = StringBuffer('email,plate,zone,start_time,end_time,amount\n');
    for (final t in _tickets) {
      buffer.writeln(t.toCsvRow().join(','));
    }
    await file.writeAsString(buffer.toString());
  }

  static Future<void> updateTicket(Ticket oldTicket, Ticket newTicket) async {
    final index = _tickets.indexWhere((t) =>
      t.email == oldTicket.email &&
      t.plate == oldTicket.plate &&
      t.zone == oldTicket.zone &&
      t.startTime == oldTicket.startTime &&
      t.endTime == oldTicket.endTime &&
      t.amount == oldTicket.amount,
    );

    if (index != -1) {
      _tickets[index] = newTicket;
      await _rewriteFile();
    }
  }
}

extension TicketUtils on Ticket {
  Duration ticketDuration() => endTime.difference(startTime);
}