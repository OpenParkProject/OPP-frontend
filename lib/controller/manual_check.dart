import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../singleton/dio_client.dart';
import '../widgets/ticket_check_widget.dart';

class ManualCheckPage extends StatefulWidget {
  final String username;
  const ManualCheckPage({super.key, required this.username});

  @override
  State<ManualCheckPage> createState() => _ManualCheckPageState();
}

class _ManualCheckPageState extends State<ManualCheckPage> {
  final TextEditingController _plateController = TextEditingController();
  List<Map<String, dynamic>> allTickets = [];
  List<Map<String, dynamic>> activeTickets = [];
  List<Map<String, dynamic>> recentExpiredTickets = [];
  List<Map<String, dynamic>> filteredHistory = [];

  bool _loading = false;
  String? _errorMessage;
  bool _showHistory = false;
  DateTime? _selectedDate;
  bool _hasSearched = false;

Future<void> _fetchTickets() async {
  _hasSearched = true;
  final plate = _plateController.text.trim().toUpperCase();

  // Check plate format
  final validPlateRegExp = RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$');
  if (!validPlateRegExp.hasMatch(plate)) {
    setState(() {
      _errorMessage = "Invalid plate format. Expected: 2 letters + 3 numbers + 2 letters (e.g. AB123CD)";
    });
    return;
  }

  setState(() {
    _loading = true;
    _errorMessage = null;
    allTickets.clear();
    activeTickets.clear();
    recentExpiredTickets.clear();
    filteredHistory.clear();
  });

  try {
    final dio = DioClient().dio;
    final response = await dio.get('/cars/$plate/tickets');
    final data = response.data;

    if (data is List) {
      final now = DateTime.now();
      for (var ticket in data) {
        try {
          final start = DateTime.parse(ticket['start_date']).toLocal();
          final end = DateTime.parse(ticket['end_date']).toLocal();
          ticket['parsed_start'] = start;
          ticket['parsed_end'] = end;
          if (ticket['creation_time'] != null) {
            try {
              final created = DateTime.parse(ticket['creation_time']).toLocal();
              ticket['parsed_creation'] = created;
            } catch (_) {
              ticket['parsed_creation'] = null;
            }
          } else {
            ticket['parsed_creation'] = null;
          }

          if (now.isAfter(start) && now.isBefore(end)) {
            activeTickets.add(ticket);
          } else if (now.isAfter(end) && now.difference(end).inMinutes <= 30) {
            recentExpiredTickets.add(ticket);
          }

          allTickets.add(ticket);
        } catch (_) {}
      }

      setState(() {
        filteredHistory = List.from(allTickets);
      });
    } else {
      setState(() {
        _errorMessage = "Unexpected server response.";
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = "Error: ${_handleError(e)}";
    });
  } finally {
    setState(() {
      _loading = false;
    });
  }
}

  void _filterHistoryByDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      filteredHistory = allTickets.where((t) {
        final start = t['parsed_start'] as DateTime;
        return start.year == date.year &&
            start.month == date.month &&
            start.day == date.day;
      }).toList();
    });
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd-MM-yyyy HH:mm').format(dt);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 1) return "less than 1 min";
    if (minutes < 60) return "$minutes min";
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return "$hours h ${rem} m";
  }

  String _handleError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('detail')) return data['detail'];
      return error.message ?? "Network error";
    }
    return error.toString();
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, {bool active = false, bool expired = false}) {
    final paid = ticket['paid'] == true;
    final start = _formatDateTime(ticket['parsed_start']);
    final end = _formatDateTime(ticket['parsed_end']);
    final price = ticket['price']?.toStringAsFixed(2) ?? '-';
    final now = DateTime.now();

    final bgColor = active
        ? (paid ? Colors.green[100] : Colors.grey[200])
        : (expired ? Colors.yellow[100] : Colors.grey[100]);

    final parsedCreation = ticket['parsed_creation'];
    final durationLeft = ticket['parsed_end'].difference(now);
    final expiredAgo = now.difference(ticket['parsed_end']);
    final createdAgo = parsedCreation != null ? now.difference(parsedCreation) : null;

    IconData icon = paid ? Icons.check_circle : Icons.warning;
    Color iconColor = paid ? Colors.green : Colors.red;

    String headerText = paid
        ? "✅ Ticket paid"
        : (active ? "⚠️ Ticket not yet paid" : "Ticket unpaid");

    String status = "Status: ${paid ? "Paid" : "Unpaid"}";
    String footer = "";
    String timeInfo = "";

    if (active) {
      if (paid) {
        footer = "Parking ticket is valid and paid.";
        timeInfo = "Expires in ${_formatDuration(durationLeft)}";
      } else {
        footer = createdAgo != null
            ? "Ticket was created ${_formatDuration(createdAgo)} ago and is not paid yet."
            : "Ticket is active but not paid yet.";
      }
    } else if (expired) {
      footer = "Ticket expired.";
      timeInfo = "Expired ${_formatDuration(expiredAgo)} ago";
    }

    return Card(
      color: bgColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headerText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text("From: $start"),
            Text("To: $end"),
            Text(status),
            Text("Price: €$price"),
            const SizedBox(height: 6),
            Text(
              footer,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (timeInfo.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  timeInfo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _filterHistoryByDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: "Enter plate number",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text("Search Tickets"),
            ),
            const SizedBox(height: 20),
            if (_plateController.text.trim().isNotEmpty)
              Expanded(
                child: TicketCheckWidget(
                  plate: _plateController.text.trim().toUpperCase(),
                  username: widget.username,
                ),
              ),
          ],
        ),
      ),
    );
  }
}