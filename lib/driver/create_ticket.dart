import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../API/client.dart';
import 'payment.dart';
import 'zone_selection.dart';

class SelectDurationPage extends StatefulWidget {
  final String plate;
  final ParkingZone selectedZone;

  const SelectDurationPage({required this.plate, required this.selectedZone, super.key});

  @override
  State<SelectDurationPage> createState() => _SelectDurationPageState();
}

class _SelectDurationPageState extends State<SelectDurationPage> {
  int _durationMinutes = 60;
  bool _isHolding = false;
  bool _startNow = true;

  final int _minMinutes = 10;
  final int _maxMinutes = 1440;
  DateTime? _scheduledDate;
  bool _creating = false;
  double _calculatePrice(int minutes) {
    final z = widget.selectedZone;
    final t = minutes / 60.0;
    return z.priceOffset + z.priceLin * t + z.priceExp * t * t;
  }


  void _changeDuration(int delta) {
    setState(() {
      _durationMinutes = (_durationMinutes + delta).clamp(_minMinutes, _maxMinutes);
    });
  }

  void _startHold(int delta) {
    _isHolding = true;
    _changeDuration(delta);
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 100));
      if (!_isHolding) return false;
      _changeDuration(delta);
      return true;
    });
  }

  void _stopHold() {
    _isHolding = false;
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now.add(Duration(minutes: 2)),
      firstDate: now,
      lastDate: now.add(Duration(days: 30)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(Duration(minutes: 2))),
    );

    if (time == null) return;

    setState(() {
      _scheduledDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _createTicket() async {
    final cost = _calculatePrice(_durationMinutes);
    final startDate = _startNow
        ? DateTime.now().add(Duration(seconds: 2))
        : (_scheduledDate ?? DateTime.now().add(Duration(minutes: 2)));

    setState(() => _creating = true);

    try {
      await DioClient().setAuthToken();
      final response = await DioClient().dio.post("/cars/${widget.plate}/tickets", data: {
        "plate": widget.plate,
        "start_date": startDate.toUtc().toIso8601String(),
        "duration": _durationMinutes,
        "zone_id": widget.selectedZone.id,
      });

      final ticketId = response.data['id'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Ticket created. You can proceed to payment now or later."),
          backgroundColor: Colors.green.shade600,
        ),
      );

      await Future.delayed(Duration(milliseconds: 300));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ParkingPaymentPage(
            ticketId: ticketId,
            plate: widget.plate,
            startDate: startDate,
            durationMinutes: _durationMinutes,
            totalCost: cost,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Ticket creation failed.")));
    } finally {
      setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cost = _calculatePrice(_durationMinutes);
    final now = DateTime.now();
    final DateTime start = _startNow
        ? now.add(Duration(seconds: 2))
        : (_scheduledDate ?? now.add(Duration(minutes: 2)));
    final DateTime end = start.add(Duration(minutes: _durationMinutes));

    return Scaffold(
      appBar: AppBar(title: Text("Select Parking Duration")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer, size: 48, color: Theme.of(context).primaryColor),
                      SizedBox(height: 20),
                      Text("Plate: ${widget.plate}", style: TextStyle(fontSize: 18)),
                      SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Schedule", style: TextStyle(fontSize: 16)),
                          Switch(
                            value: _startNow,
                            onChanged: (v) => setState(() => _startNow = v),
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          Text("Start immediately", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      if (!_startNow)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.calendar_today),
                            label: Text(
                              _scheduledDate == null
                                  ? "Pick start date and time"
                                  : "Start at: ${DateFormat('dd/MM – HH:mm').format(_scheduledDate!)}",
                            ),
                            onPressed: _pickDateTime,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade400,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(onPressed: () => _changeDuration(-60), child: Text("-1h")),
                          GestureDetector(
                            onTapDown: (_) => _startHold(-10),
                            onTapUp: (_) => _stopHold(),
                            onTapCancel: () => _stopHold(),
                            child: OutlinedButton(onPressed: () => _changeDuration(-10), child: Text("-10m")),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              _durationMinutes < 60
                                  ? "${_durationMinutes % 60}m"
                                  : "${_durationMinutes ~/ 60}h ${_durationMinutes % 60}m",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          GestureDetector(
                            onTapDown: (_) => _startHold(10),
                            onTapUp: (_) => _stopHold(),
                            onTapCancel: () => _stopHold(),
                            child: OutlinedButton(onPressed: () => _changeDuration(10), child: Text("+10m")),
                          ),
                          OutlinedButton(onPressed: () => _changeDuration(60), child: Text("+1h")),
                        ],
                      ),

                      SizedBox(height: 20),
                      Text(
                        "Expires at: ${DateFormat('dd/MM - HH:mm').format(end)}",
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Estimated cost: €${cost.toStringAsFixed(2)}", style: TextStyle(fontSize: 18)),
                          SizedBox(width: 6),
                          IconButton(
                            icon: Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                            tooltip: "How pricing works",
                            onPressed: () {
                              final z = widget.selectedZone;
                              final offset = z.priceOffset.toStringAsFixed(2);
                              final lin = z.priceLin.toStringAsFixed(2);
                              final exp = z.priceExp.toStringAsFixed(2);
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("How the cost is calculated"),
                                  content: Text(
                                    "The parking cost is calculated using a dynamic pricing formula:\n\n"
                                    "Cost = offset + linear × t + exponential × t²\n\n"
                                    "Where:\n"
                                    "- offset = €$offset\n"
                                    "- linear (€/hour) = €$lin\n"
                                    "- exponential (€/hour²) = €$exp\n"
                                    "- t = duration in hours (e.g. 1.5h)\n",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 40),

                      ElevatedButton.icon(
                        icon: _creating
                            ? CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                            : Icon(Icons.check),
                        label: Text("Create ticket"),
                        onPressed: _creating ? null : _createTicket,
                        style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}