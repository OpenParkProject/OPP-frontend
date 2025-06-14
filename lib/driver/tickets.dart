import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../API/client.dart';
import '../widgets/clock_widget.dart';
import 'zone_selection.dart';
import 'payment.dart';
import 'extend_ticket.dart';
import 'dart:async';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../main.dart';
class UserTicketsPage extends StatefulWidget {
  const UserTicketsPage({super.key});

  static Route<void> routeWithRefresh() {
    return MaterialPageRoute(
      builder: (context) => const UserTicketsPage(),
      settings: RouteSettings(name: 'tickets_page'),
    );
  }

  @override
  State<UserTicketsPage> createState() => _UserTicketsPageState();
}

class _UserTicketsPageState extends State<UserTicketsPage> with RouteAware {
  Timer? refreshTimer;
  Map<int, String> zoneNames = {};
  List<Map<String, dynamic>> activeTickets = [];
  List<Map<String, dynamic>> scheduledPaid = [];
  List<Map<String, dynamic>> scheduledUnpaid = [];
  List<Map<String, dynamic>> expiredTickets = [];
  List<Map<String, dynamic>> allTickets = [];
  List<Map<String, dynamic>> mergeTickets(List<Map<String, dynamic>> tickets) {
    tickets.sort((a, b) {
      final plateA = a['plate'] ?? '';
      final plateB = b['plate'] ?? '';
      final sa = DateTime.tryParse(a['start_date'] ?? '') ?? DateTime(2100);
      final sb = DateTime.tryParse(b['start_date'] ?? '') ?? DateTime(2100);

      final cmpPlate = plateA.compareTo(plateB);
      if (cmpPlate != 0) return cmpPlate;
      return sa.compareTo(sb);
    });

    List<Map<String, dynamic>> result = [];
    int i = 0;

    while (i < tickets.length) {
      final current = tickets[i];
      final chain = [current];
      DateTime? currentEnd = DateTime.tryParse(current['end_date'] ?? '')?.toUtc();
      int j = i + 1;

      while (j < tickets.length) {
        final next = tickets[j];
        final nextStart = DateTime.tryParse(next['start_date'] ?? '')?.toUtc();
        final samePlate = current['plate'] == next['plate'];
        final sameZone = current['zone_id'] == next['zone_id'];
        final contiguous = currentEnd != null && nextStart != null &&
            (nextStart.difference(currentEnd).inSeconds).abs() <= 1;

        if (samePlate && sameZone && contiguous) {
          chain.add(next);
          currentEnd = DateTime.tryParse(next['end_date'] ?? '')?.toUtc();
          j++;
        } else {
          break;
        }
      }

      if (chain.length > 1) {
        final startDate = chain.first['start_date'];
        final endDate = chain.last['end_date'];
        final totalPrice = chain.fold<double>(0.0, (sum, t) {
          final p = t['price'];
          return sum + (p is num ? p.toDouble() : double.tryParse('$p') ?? 0.0);
        });
        final mergedIds = chain.map((t) => t['id']).toList();

        result.add({
          ...current,
          'start_date': startDate,
          'end_date': endDate,
          'price': totalPrice,
          'extended': true,
          'merged_ids': mergedIds,
        });

        i += chain.length;
      } else {
        result.add(current);
        i++;
      }
    }

    return result;
  }

  bool loading = true;
  String? errorMsg;
  bool showExpired = false;

  Map<String, dynamic>? findSubTicket(int subId) {
    try {
      return allTickets.firstWhere((t) => t['id'] == subId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTickets();

    refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _refreshActiveStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint("Tickets refreshed");
    _fetchTickets();
  }

  void _refreshActiveStatus() {
    final now = DateTime.now();

    final stillActive = <Map<String, dynamic>>[];
    final nowExpired = <Map<String, dynamic>>[];

    for (final ticket in activeTickets) {
      final start = DateTime.tryParse(ticket['start_date'] ?? '')?.toLocal();
      final end = DateTime.tryParse(ticket['end_date'] ?? '')?.toLocal();
      if (start == null || end == null) continue;

      if (now.isAfter(end)) {
        nowExpired.add(ticket);
      } else {
        stillActive.add(ticket);
      }
    }

    if (nowExpired.isNotEmpty) {
      setState(() {
        activeTickets = stillActive;
        expiredTickets.addAll(nowExpired);
      });
    }
  }

  Future<void> _fetchTickets() async {
    debugPrint("Fetchticket called");
    setState(() {
      loading = true;
      allTickets.clear();
      activeTickets.clear();
      scheduledPaid.clear();
      scheduledUnpaid.clear();
      expiredTickets.clear();
      errorMsg = null;
    });

    try {
      await DioClient().setAuthToken();
      final response = await DioClient().dio.get('/users/me/tickets');
      final now = DateTime.now();

      allTickets = List<Map<String, dynamic>>.from(response.data);
      List<Map<String, dynamic>> toMerge = [];

      scheduledUnpaid = []; // reset

      for (var t in response.data) {
        final rawStart = DateTime.tryParse(t['start_date'] ?? '');
        final rawEnd = DateTime.tryParse(t['end_date'] ?? '');
        final start = rawStart?.toLocal();
        final end = rawEnd?.toLocal();
        if (start != null) t['start_date'] = start.toIso8601String();
        if (end != null) t['end_date'] = end.toIso8601String();

        final paid = t['paid'] == true;

        if (start == null || end == null) continue;

        if (paid) {
          toMerge.add(t);
        } else {
          scheduledUnpaid.add(t);
        }
      }

      // ✅ Fonde i ticket consecutivi pagati con stessa targa e zona
      final mergedTickets = mergeTickets(toMerge);
      activeTickets = [];
      scheduledPaid = [];
      expiredTickets = [];

      for (var t in mergedTickets) {
        final start = DateTime.tryParse(t['start_date'])?.toLocal();
        final end = DateTime.tryParse(t['end_date'])?.toLocal();
        if (start == null || end == null) continue;

        if (end.isBefore(now)) {
          expiredTickets.add(t);
        } else if (now.isAfter(start.subtract(Duration(minutes: 1))) &&
                  now.isBefore(end.add(Duration(minutes: 1)))) {
          activeTickets.add(t);
        } else {
          scheduledPaid.add(t);
        }
      }

      final allZoneIds = mergedTickets.map((t) => t['zone_id']).toSet();

      for (final zoneId in allZoneIds) {
        if (zoneId != null && !zoneNames.containsKey(zoneId)) {
          try {
            final zoneRes = await DioClient().dio.get('/zones/$zoneId');
            final zoneName = zoneRes.data['name'];
            zoneNames[zoneId] = zoneName ?? '';
          } catch (e) {
            zoneNames[zoneId] = '';
          }
        }
      }

      setState(() => loading = false);
    } catch (e) {
      setState(() {
        errorMsg = "❌ Failed to load tickets.";
        loading = false;
      });
    }
  }

  Future<void> generateAndDownloadReceipt(Map<String, dynamic> ticket) async {
    final pdf = pw.Document();
    final plate = ticket['plate'] ?? '—';
    final zoneName = zoneNames[ticket['zone_id']] ?? 'Unknown';
    final now = DateTime.now();
    final formatter = DateFormat('MM/dd/yyyy hh:mm a');
    final isExtended = ticket['extended'] == true;
    final mergedIds = ticket['merged_ids'] ?? [];

    // Helper to format sub-ticket row
    pw.Widget formatRow(DateTime s, DateTime e, double p, int index) {
      final duration = e.difference(s);
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Part ${index + 1}: ${formatter.format(s)} -> ${formatter.format(e)}",
            style: pw.TextStyle(font: pw.Font.courier(), fontSize: 11),
          ),
          pw.Text(
            "          Duration: ${duration.inHours} h ${duration.inMinutes % 60} m \n          Price: ${p.toStringAsFixed(2)} EUR",
            style: pw.TextStyle(font: pw.Font.courier(), fontSize: 11),
          ),
          pw.SizedBox(height: 4),
        ],
      );
    }

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          final List<pw.Widget> children = [];

          children.addAll([
            pw.Text('OpenPark', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Ticket #: ${ticket['id']}', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12)),
            pw.Text('Plate: $plate', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12)),
            pw.Text('Zone: $zoneName', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12)),
            pw.SizedBox(height: 12),
          ]);
          if (isExtended && mergedIds.isNotEmpty) {
            final firstSub = findSubTicket(mergedIds[0]);
            final start0 = DateTime.tryParse(firstSub?['start_date'] ?? '')?.toLocal();
            final end0 = DateTime.tryParse(firstSub?['end_date'] ?? '')?.toLocal();
            final price0 = firstSub?['price']?.toDouble() ?? 0.0;

            children.addAll([
              pw.Text('Initial Ticket:', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12)),
              pw.Text('Start: ${formatter.format(start0!)}', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12)),
              pw.Text('End:   ${formatter.format(end0!)}', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12)),
              pw.Text('Duration: ${end0.difference(start0).inHours} h ${end0.difference(start0).inMinutes % 60} m',
                  style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12)),
              pw.Text('Price:    ${price0.toStringAsFixed(2)} EUR', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.Text('Extensions:', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12)),
            ]);

              DateTime lastEnd = end0;
              for (int i = 1; i < mergedIds.length; i++) {
                final subId = mergedIds[i];
                final subTicket = findSubTicket(subId);
                if (subTicket == null) continue;

                final end = DateTime.tryParse(subTicket['end_date'] ?? '')?.toLocal();
                final p = subTicket['price'];
                final price = (p is num) ? p.toDouble() : (p is String ? double.tryParse(p) ?? 0.0 : 0.0);

                if (end != null) {
                  final extraMin = end.difference(lastEnd).inMinutes;
                  children.add(
                    pw.Text(
                      "+${extraMin} min -> new end: ${formatter.format(end)}   +${price.toStringAsFixed(2)} EUR",
                      style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12),
                    ),
                  );
                  lastEnd = end;
                }
              }
          } else {
            // Ticket singolo
            final start = DateTime.tryParse(ticket['start_date'] ?? '')?.toLocal();
            final end = DateTime.tryParse(ticket['end_date'] ?? '')?.toLocal();
            final price = ticket['price']?.toDouble() ?? 0.0;
            if (start != null && end != null) {
              children.add(formatRow(start, end, price, 0));
            }
          }

          // Riepilogo finale
          final globalStart = DateTime.tryParse(ticket['start_date'] ?? '')?.toLocal();
          final globalEnd = DateTime.tryParse(ticket['end_date'] ?? '')?.toLocal();
          double totalPrice;
          if (isExtended && mergedIds.length > 1) {
            totalPrice = 0.0;
            for (final subId in mergedIds) {
              final subTicket = findSubTicket(subId);
              final p = subTicket?['price'];
              if (p is num) totalPrice += p;
              if (p is String) totalPrice += double.tryParse(p) ?? 0.0;
            }
          } else {
            totalPrice = ticket['price']?.toDouble() ?? 0.0;
          }

          if (globalStart != null && globalEnd != null) {
            final totalDuration = globalEnd.difference(globalStart);
            children.addAll([
              pw.SizedBox(height: 8),
              pw.Text('------------------------------', style: pw.TextStyle(font: pw.Font.courier())),
              pw.Text('TOTAL DURATION: ${totalDuration.inHours} h ${totalDuration.inMinutes % 60} m',
                  style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12)),
              pw.Text('TOTAL PRICE:    ${totalPrice.toStringAsFixed(2)} EUR',
                  style: pw.TextStyle(font: pw.Font.courier(), fontSize: 13)),
              pw.Text('Date Issued:    ${formatter.format(now)}',
                  style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10)),
              pw.SizedBox(height: 16),
              pw.Center(child: pw.Text('Thank you for parking with us :)', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12))),
            ]);
          }

          return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children);
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/receipt_$plate${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
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

    double price;
    if (ticket['extended'] == true && ticket['merged_ids'] != null) {
      price = 0.0;
      for (final subId in ticket['merged_ids']) {
        final subTicket = findSubTicket(subId);
        final p = subTicket?['price'];
        if (p is num) price += p;
        if (p is String) price += double.tryParse(p) ?? 0.0;
      }
    } else {
      price = _parsePrice(ticket['price']);
    }

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
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      "Extended ticket",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Spacer(),
                    // Mostra l’orario di fine del ticket precedente
                    if (ticket['merged_ids'] != null && ticket['merged_ids'].length >= 2)
                      Builder(builder: (_) {
                        final prevId      = ticket['merged_ids'][ticket['merged_ids'].length - 2];
                        final prevTicket  = findSubTicket(prevId);
                        final prevEnd     = DateTime.tryParse(prevTicket?['end_date'] ?? '')?.toLocal();

                        return prevEnd != null
                            ? Text(
                                "Prev. end: ${DateFormat('HH:mm').format(prevEnd)}",
                                style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                              )
                            : const SizedBox.shrink();
                      }),
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
              Text(
                "Zone ${ticket['zone_id'] ?? '?'}"
                "${zoneNames[ticket['zone_id']] != null && zoneNames[ticket['zone_id']]!.isNotEmpty ? ' – ${zoneNames[ticket['zone_id']]}' : ''}",
              ),
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
                          await DioClient().setAuthToken();
                          await DioClient().dio.delete('/tickets/$id');

                          setState(() {
                            scheduledUnpaid.removeWhere((t) => t['id'] == id);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🗑️ Ticket deleted.")));

                          _fetchTickets();
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
                            generateAndDownloadReceipt(ticket);
                          }
                        : () async {
                            scheduledUnpaid.clear();

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ParkingPaymentPage(
                                  ticketId: id,
                                  plate: plate,
                                  startDate: start!,
                                  durationMinutes: end!.difference(start).inMinutes,
                                  totalCost: price,
                                  allowPayLater: false,
                                  zoneName: zoneNames[ticket['zone_id']] ?? '',
                                ),
                              ),
                            );

                            if (result == true) {
                              await Future.delayed(Duration(milliseconds: 300));
                              await _fetchTickets();
                            }
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
                        onPressed: () async {
                          DateTime newStart = start!;
                          DateTime newEnd = end!;
                          double newPrice = _parsePrice(ticket['price']);

                          if (ticket['merged_ids'] != null && ticket['merged_ids'].isNotEmpty) {
                            final mergedIds = List<int>.from(ticket['merged_ids']);
                            double fullPrice = 0.0;
                            DateTime? lastEnd;

                            for (final subId in mergedIds) {
                              final sub = findSubTicket(subId);
                              final price = sub?['price'];
                              if (price is num) fullPrice += price;
                              if (price is String) fullPrice += double.tryParse(price) ?? 0.0;

                              final e = DateTime.tryParse(sub?['end_date'] ?? '')?.toLocal();
                              if (e != null) lastEnd = e;
                            }

                            if (lastEnd != null) {
                              newEnd = lastEnd;
                              newPrice = fullPrice;
                            }
                          }


                      try {
                        await DioClient().setAuthToken();
                        final zoneRes = await DioClient().dio.get('/zones/${ticket['zone_id']}');
                        final zone = zoneRes.data;

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExtendTicketPage(
                              ticketId: id,
                              plate: plate,
                              oldStart: newStart,
                              oldEnd: newEnd,
                              oldPrice: newPrice,
                              zoneId: ticket['zone_id'],
                            ),
                          ),
                        );

                        if (result == true) {
                          await Future.delayed(Duration(milliseconds: 300));
                          await _fetchTickets();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("❌ Failed to fetch zone info")),
                        );
                      }
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
          await Future.delayed(Duration(milliseconds: 300));
          await _fetchTickets();
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
