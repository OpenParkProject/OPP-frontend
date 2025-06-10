import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../API/client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/issue_fine.dart';

class TicketCheckWidget extends StatefulWidget {
  final String plate;
  final String username;
  const TicketCheckWidget({super.key, required this.plate, required this.username});

  @override
  State<TicketCheckWidget> createState() => _TicketCheckWidgetState();
}

class _TicketCheckWidgetState extends State<TicketCheckWidget> {
  List<Map<String, dynamic>> allTickets = [];
  List<Map<String, dynamic>> activeTickets = [];
  List<Map<String, dynamic>> recentExpiredTickets = [];
  List<Map<String, dynamic>> filteredHistory = [];
  List<int> assignedZoneIds = [];

  bool _loading = false;
  String? _errorMessage;
  bool _showHistory = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadAssignedZones().then((_) => _fetchTickets());
  }

  Future<void> _loadAssignedZones() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList("zone_ids"); // corretto nome
    if (ids != null) {
      assignedZoneIds = ids.map((e) => int.tryParse(e)).whereType<int>().toList();
    }
  }
  
  Future<void> _fetchTickets() async {
    final plate = widget.plate.toLowerCase(); // confronti case-insensitive
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
      final now = DateTime.now();

      for (final zid in assignedZoneIds) {
        final res = await dio.get('/zones/$zid/tickets', queryParameters: {
          'limit': 100,
          'valid_only': false,
        });

        if (res.data is List) {
          for (final t in res.data) {
            if ((t['plate'] ?? '').toString().toLowerCase() != plate) continue;

            try {
              final start = DateTime.parse(t['start_date']).toLocal();
              final end = DateTime.parse(t['end_date']).toLocal();
              t['parsed_start'] = start;
              t['parsed_end'] = end;

              if (t['creation_time'] != null) {
                try {
                  t['parsed_creation'] = DateTime.parse(t['creation_time']).toLocal();
                } catch (_) {
                  t['parsed_creation'] = null;
                }
              } else {
                t['parsed_creation'] = null;
              }

              allTickets.add(t);

              if (now.isAfter(start) && now.isBefore(end)) {
                activeTickets.add(t);
              } else if (now.isAfter(end) && now.difference(end).inMinutes <= 30) {
                recentExpiredTickets.add(t);
              }
            } catch (e) {
              debugPrint("⚠️ Failed to parse ticket: $e");
            }
          }
        }
      }

      setState(() {
        filteredHistory = List.from(allTickets);
      });
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
        return start.year == date.year && start.month == date.month && start.day == date.day;
      }).toList();
    });
  }

  String _formatDateTime(DateTime dt) => DateFormat('dd-MM-yyyy HH:mm').format(dt);
  String _formatDuration(Duration d) =>
      d.inMinutes < 1 ? "less than 1 min" : d.inMinutes < 60 ? "${d.inMinutes} min" : "${d.inMinutes ~/ 60} h ${d.inMinutes % 60} m";

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

    final bgColor = active ? (paid ? Colors.green[100] : Colors.grey[200]) : (expired ? Colors.yellow[100] : Colors.grey[100]);

    final parsedCreation = ticket['parsed_creation'];
    final durationLeft = ticket['parsed_end'].difference(now);
    final expiredAgo = now.difference(ticket['parsed_end']);
    final createdAgo = parsedCreation != null ? now.difference(parsedCreation) : null;

    String headerText = paid ? "✅ Ticket paid" : (active ? "⚠️ Ticket not yet paid" : "Ticket unpaid");
    String status = "Status: ${paid ? "Paid" : "Unpaid"}";
    String footer = active
        ? (paid
            ? "Parking ticket is valid and paid."
            : createdAgo != null
                ? "Ticket was created ${_formatDuration(createdAgo)} ago and is not paid yet."
                : "Ticket is active but not paid yet.")
        : "Ticket expired.";
    String timeInfo = active && paid
        ? "Expires in ${_formatDuration(durationLeft)}"
        : expired
            ? "Expired ${_formatDuration(expiredAgo)} ago"
            : "";

    return Card(
      color: bgColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(headerText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text("From: $start"),
          Text("To: $end"),
          Text(status),
          Text("Price: €$price"),
          const SizedBox(height: 6),
          Text(footer, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (timeInfo.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Text(timeInfo, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ]),
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
    if (picked != null) _filterHistoryByDate(picked);
  }

@override
  Widget build(BuildContext context) {
    final plate = widget.plate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loading) const LinearProgressIndicator(),
        const SizedBox(height: 10),
        if (_errorMessage != null)
          Text(_errorMessage!, style: const TextStyle(color: Colors.red))
        else ...[
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
                  Expanded(child: Text("❌ No valid parking ticket found for this plate."))
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit_location_alt),
                  label: const Text("Chalk Vehicle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    final reasonController = TextEditingController();
                    final notesController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text("Chalk vehicle $plate"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: reasonController, decoration: const InputDecoration(labelText: "Reason (optional)")),
                            TextField(controller: notesController, decoration: const InputDecoration(labelText: "Notes (optional)")),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                await DioClient().dio.post('/api/v1/chalk', data: {
                                  'plate': plate,
                                  'controller_username': widget.username,
                                  'reason': reasonController.text,
                                  'notes': notesController.text,
                                });
                                if (!mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vehicle successfully chalked")));
                              } catch (e) {
                                if (!mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error chalking vehicle: ${e.toString()}")));
                              }
                            },
                            child: const Text("Confirm Chalk"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.gavel),
                  label: const Text("Issue Fine"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/issue_fine', arguments: plate);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activeTickets.isNotEmpty) ...[
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
              SizedBox(
                height: 400,
                child: filteredHistory.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("No tickets found for the selected date."),
                      )
                    : ListView.builder(
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final t = filteredHistory[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: _buildTicketCard(t),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}