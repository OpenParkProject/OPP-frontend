import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../singleton/dio_client.dart';

class ManualCheckPage extends StatefulWidget {
  const ManualCheckPage({super.key});

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
    if (plate.isEmpty) return;

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
              onSubmitted: (_) => _fetchTickets(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchTickets,
              child: const Text("Search Tickets"),
            ),
            const SizedBox(height: 20),
            if (!_hasSearched)
              const SizedBox.shrink()
            else if (_loading)
              const CircularProgressIndicator()
            else if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activeTickets.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text("❌ No valid parking ticket found for this plate."),
                              )
                            ],
                          ),
                        )
                      else ...[
                        const Text("Active Tickets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...activeTickets.map((t) => _buildTicketCard(t, active: true)),
                        const Divider(),
                      ],
                      if (recentExpiredTickets.isNotEmpty) ...[
                        const Text("Recently Expired Tickets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...recentExpiredTickets.map((t) => _buildTicketCard(t, expired: true)),
                        const Divider(),
                      ],
                      ExpansionTile(
                        title: const Text("Ticket History"),
                        initiallyExpanded: _showHistory,
                        onExpansionChanged: (expanded) => setState(() => _showHistory = expanded),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _selectDate(context),
                                  child: const Text("Select date"),
                                ),
                                const SizedBox(width: 12),
                                Text(_selectedDate != null
                                    ? DateFormat('dd-MM-yyyy').format(_selectedDate!)
                                    : "No date selected"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (filteredHistory.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("No tickets found for the selected date."),
                            )
                          else
                            ...filteredHistory.map((t) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 0),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                                    child: _buildTicketCard(t),
                                  ),
                                )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}