import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../API/client.dart';
import '../widgets/clock_widget.dart';
import 'zone_selection.dart';
import 'payment.dart';
import 'extend_ticket.dart';

class UserTicketsPage extends StatefulWidget {
  const UserTicketsPage({super.key});

  @override
  State<UserTicketsPage> createState() => _UserTicketsPageState();
}

class _UserTicketsPageState extends State<UserTicketsPage> {
  List<Map<String, dynamic>> activeTickets = [];
  List<Map<String, dynamic>> scheduledPaid = [];
  List<Map<String, dynamic>> scheduledUnpaid = [];
  List<Map<String, dynamic>> expiredTickets = [];
  List<Map<String, dynamic>> mergeTickets(List<Map<String, dynamic>> tickets) {
    tickets.sort((a, b) {
      final sa = DateTime.tryParse(a['start_date'] ?? '') ?? DateTime(2100);
      final sb = DateTime.tryParse(b['start_date'] ?? '') ?? DateTime(2100);
      return sa.compareTo(sb);
    });

    List<List<Map<String, dynamic>>> groups = [];
    List<Map<String, dynamic>> currentGroup = [];

    for (var ticket in tickets) {
      final start = DateTime.tryParse(ticket['start_date'] ?? '');
      final end = DateTime.tryParse(ticket['end_date'] ?? '');
      if (start == null || end == null) continue;

      if (currentGroup.isEmpty) {
        currentGroup.add(ticket);
      } else {
        final last = currentGroup.last;
        final lastEnd = DateTime.tryParse(last['end_date'] ?? '');
        if (ticket['plate'] == last['plate'] &&
            ticket['zone_id'] == last['zone_id'] &&
            lastEnd != null &&
            start == lastEnd) {
          currentGroup.add(ticket);
        } else {
          groups.add(List.from(currentGroup));
          currentGroup = [ticket];
        }
      }
    }
    if (currentGroup.isNotEmpty) groups.add(currentGroup);

    return groups.map((g) {
      if (g.length == 1) return g.first;
      final price = g.fold<double>(0, (sum, t) {
        final p = t['price'];
        if (p is num) return sum + p.toDouble();
        if (p is String) return sum + (double.tryParse(p) ?? 0.0);
        return sum;
      });

      return {
        ...g.first,
        'start_date': g.first['start_date'],
        'end_date': g.last['end_date'],
        'price': price,
        'extended': true,
        'merged_ids': g.map((t) => t['id']).toList(),
      };
    }).toList();
  }

  bool loading = true;
  String? errorMsg;
  bool showExpired = false;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => loading = true);
    try {
      await DioClient().setAuthToken();
      final response = await DioClient().dio.get('/users/me/tickets');
      final now = DateTime.now();

      List<Map<String, dynamic>> originalActive = [];
      scheduledPaid.clear();
      scheduledUnpaid.clear();
      expiredTickets.clear();

      for (var t in response.data) {
        final rawStart = DateTime.tryParse(t['start_date'] ?? '');
        final rawEnd = DateTime.tryParse(t['end_date'] ?? '');
        final start = rawStart?.toLocal();
        final end = rawEnd?.toLocal();
        final paid = t['paid'] == true;

        if (start == null || end == null) continue;

        if (end.isBefore(now)) {
          expiredTickets.add(t);
        } else if (paid && now.isAfter(start.subtract(Duration(minutes: 1))) && now.isBefore(end.add(Duration(minutes: 1)))) {
          originalActive.add(t);
        } else if (paid) {
          scheduledPaid.add(t);
        } else {
          scheduledUnpaid.add(t);
        }
      }

      int compareDates(String? a, String? b) {
        final da = DateTime.tryParse(a ?? '')?.toLocal();
        final db = DateTime.tryParse(b ?? '')?.toLocal();
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      }

      scheduledPaid.sort((a, b) => compareDates(a['start_date'], b['start_date']));
      scheduledUnpaid.sort((a, b) => compareDates(a['start_date'], b['start_date']));

      activeTickets = mergeTickets(originalActive);
      setState(() => loading = false);
    } catch (e) {
      setState(() {
        errorMsg = "❌ Failed to load tickets.";
        loading = false;
      });
    }
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, {bool isExpired = false}) {
    final start = DateTime.tryParse(ticket['start_date'] ?? '')?.toLocal();
    final end = DateTime.tryParse(ticket['end_date'] ?? '')?.toLocal();
    final plate = ticket['plate'] ?? '—';
    double _parsePrice(dynamic p) {
      if (p == null) return 0.0;
      if (p is num) return p.toDouble();
      if (p is String) return double.tryParse(p) ?? 0.0;
      return 0.0;
    }

    final price = _parsePrice(ticket['price']);

    final paid = ticket['paid'] == true;
    final isExtended = ticket['extended'] == true;
    final id = ticket['id'];
    final now = DateTime.now();
    final isActive = paid && start != null && end != null && now.isAfter(start) && now.isBefore(end);

    final dateFormat = DateFormat('dd/MM – HH:mm');

    return Card(
      color: Colors.grey[100],
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(paid ? Icons.check_circle : Icons.schedule, color: paid ? Colors.green : Colors.orange),
                SizedBox(width: 8),
                Text("Plate: $plate", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Spacer(),
                Text("€${price.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (isExtended)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.blueAccent),
                    SizedBox(width: 6),
                    Text("Extended ticket", style: TextStyle(color: Colors.blueAccent)),
                  ],
                ),
              ),
            SizedBox(height: 12),
            if (start != null && end != null) ...[
              Row(children: [Icon(Icons.login, size: 16), SizedBox(width: 6), Text("Start: ${dateFormat.format(start)}")]),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.logout, size: 16),
                  SizedBox(width: 6),
                  isActive
                      ? Text("Expires at: ${DateFormat('HH:mm').format(end)}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade400))
                      : Text("Expiration:   ${dateFormat.format(end)}"),
                ],
              ),
            ],
            SizedBox(height: 6),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 16),
              SizedBox(width: 6),
              Text("Zone: ${ticket['zone_id'] ?? 'Unknown'}"),
            ]),            SizedBox(height: 10),
            if (!isExpired || (isExpired && paid))
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    if (!isExpired && !paid)
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await DioClient().setAuthToken();
                            await DioClient().dio.delete('/tickets/$id');
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🗑️ Ticket deleted.")));
                            _fetchTickets();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Deletion failed.")));
                          }
                        },
                        icon: Icon(Icons.delete, size: 18),
                        label: Text("Delete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: paid
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("📄 Receipt download not yet implemented.")));
                            }
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ParkingPaymentPage(
                                    ticketId: id,
                                    plate: plate,
                                    startDate: start!,
                                    durationMinutes: end!.difference(start).inMinutes,
                                    totalCost: price,
                                  ),
                                ),
                              );
                              await Future.delayed(Duration(milliseconds: 500));
                              _fetchTickets();
                            },
                      icon: Icon(paid ? Icons.download : Icons.payment, size: 18),
                      label: Text(paid ? "Download receipt" : "Pay now"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: paid ? Colors.green : Colors.orangeAccent.shade100,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    if (!isExpired && paid && start != null && end != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExtendTicketPage(
                                ticketId: id,
                                plate: plate,
                                oldStart: start,
                                oldEnd: end,
                                oldPrice: price,
                                zoneId: ticket['zone_id'],
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.schedule_send),
                        label: Text("Extend"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Your Tickets"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: ClockWidget(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ParkingZoneSelectionPage()),
          );
          await Future.delayed(Duration(milliseconds: 500));
          _fetchTickets();
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text("New Ticket"),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: loading
                  ? Center(child: CircularProgressIndicator())
                  : errorMsg != null
                      ? Center(child: Text(errorMsg!))
        : (activeTickets.isEmpty &&
          scheduledPaid.isEmpty &&
          scheduledUnpaid.isEmpty &&
          expiredTickets.isEmpty)
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_empty, size: 80, color: Colors.grey.shade400),
                    SizedBox(height: 16),
                    Text(
                      "You don't have any tickets yet.",
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Tap the ➕ button below to get started!",
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView(
              children: [
                if (activeTickets.isNotEmpty) ...[
                  Text("Currently Active", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ...activeTickets.map((t) => _buildTicketCard(t)),
                  Divider(height: 32, thickness: 2),
                ],
                if (scheduledPaid.isNotEmpty) ...[
                  Text("Scheduled – Paid", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ...scheduledPaid.map((t) => _buildTicketCard(t)),
                  Divider(height: 32, thickness: 2),
                ],
                if (scheduledUnpaid.isNotEmpty) ...[
                  Text("Scheduled – Not Paid", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ...scheduledUnpaid.map((t) => _buildTicketCard(t)),
                  Divider(height: 32, thickness: 2),
                ],
                if (activeTickets.isEmpty &&
                    scheduledPaid.isEmpty &&
                    scheduledUnpaid.isEmpty &&
                    expiredTickets.isNotEmpty) ...[
                  SizedBox(height: 32),
                  Column(
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
                      SizedBox(height: 16),
                      Text(
                        "You don't have any active tickets.",
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Tap the ➕ button below to create a new one.",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                ],
                if (expiredTickets.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => setState(() => showExpired = !showExpired),
                    child: Row(
                      children: [
                        Icon(showExpired ? Icons.expand_less : Icons.expand_more),
                        SizedBox(width: 8),
                        Text("Expired Tickets", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  AnimatedCrossFade(
                    crossFadeState: showExpired ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    duration: Duration(milliseconds: 300),
                    firstChild: Column(
                      children: expiredTickets.map((t) => _buildTicketCard(t, isExpired: true)).toList(),
                    ),
                    secondChild: SizedBox.shrink(),
                  ),
                ],
              ],
            )
            ),
          ),
        ],
      ),
    );
  }
}
