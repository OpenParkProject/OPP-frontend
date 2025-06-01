import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../singleton/dio_client.dart';

class SelectDurationPage extends StatefulWidget {
  final String plate;

  const SelectDurationPage({required this.plate, super.key});

  @override
  State<SelectDurationPage> createState() => _SelectDurationPageState();
}

class _SelectDurationPageState extends State<SelectDurationPage> {
  int _durationMinutes = 60;
  final double _pricePerMinute = 0.02;
  bool _isHolding = false;
  bool _startNow = true;

  final int _minMinutes = 10;
  final int _maxMinutes = 1440;
  DateTime? _scheduledDate;
  bool _creating = false;

  void _changeDuration(int delta) {
    setState(() {
      _durationMinutes = (_durationMinutes + delta).clamp(
        _minMinutes,
        _maxMinutes,
      );
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
      _scheduledDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _createTicket() async {
    final cost = _durationMinutes * _pricePerMinute;
    final startDate =
        _startNow
            ? DateTime.now().add(Duration(seconds: 2))
            : (_scheduledDate ?? DateTime.now().add(Duration(minutes: 2)));

    setState(() => _creating = true);

    try {
      await DioClient().setAuthToken();
      final response = await DioClient().dio.post(
        "/cars/${widget.plate}/tickets",
        data: {
          "plate": widget.plate,
          "start_date": startDate.toUtc().toIso8601String(),
          "duration": _durationMinutes,
        },
      );

      final ticketId = response.data['id'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Ticket created."),
          backgroundColor: Colors.green.shade600,
        ),
      );

      await Future.delayed(Duration(milliseconds: 300));
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Ticket creation failed.")));
    } finally {
      setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cost = _durationMinutes * _pricePerMinute;
    final now = DateTime.now();
    final DateTime start =
        _startNow
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
                      Icon(
                        Icons.timer,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Plate: ${widget.plate}",
                        style: TextStyle(fontSize: 18),
                      ),
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
                          Text(
                            "Start immediately",
                            style: TextStyle(fontSize: 16),
                          ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () => _changeDuration(-60),
                            child: Text("-1h"),
                          ),
                          GestureDetector(
                            onTapDown: (_) => _startHold(-10),
                            onTapUp: (_) => _stopHold(),
                            onTapCancel: () => _stopHold(),
                            child: OutlinedButton(
                              onPressed: () => _changeDuration(-10),
                              child: Text("-10m"),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Text(
                              _durationMinutes < 60
                                  ? "${_durationMinutes % 60}m"
                                  : "${_durationMinutes ~/ 60}h ${_durationMinutes % 60}m",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTapDown: (_) => _startHold(10),
                            onTapUp: (_) => _stopHold(),
                            onTapCancel: () => _stopHold(),
                            child: OutlinedButton(
                              onPressed: () => _changeDuration(10),
                              child: Text("+10m"),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => _changeDuration(60),
                            child: Text("+1h"),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),
                      Text(
                        "Expires at: ${DateFormat('dd/MM - HH:mm').format(end)}",
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Estimated cost: €${cost.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 40),

                      ElevatedButton.icon(
                        icon:
                            _creating
                                ? CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                )
                                : Icon(Icons.check),
                        label: Text("Create ticket"),
                        onPressed: _creating ? null : _createTicket,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                        ),
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

class ExtendTicketPage extends StatefulWidget {
  final int ticketId;
  final String plate;
  final DateTime oldStart;
  final DateTime oldEnd;
  final double oldPrice;

  const ExtendTicketPage({
    required this.ticketId,
    required this.plate,
    required this.oldStart,
    required this.oldEnd,
    required this.oldPrice,
    super.key,
  });

  @override
  State<ExtendTicketPage> createState() => _ExtendTicketPageState();
}

class _ExtendTicketPageState extends State<ExtendTicketPage> {
  int extraMinutes = 30;
  final double pricePerMinute = 0.02;

  void _changeDuration(int delta) {
    setState(() {
      extraMinutes = (extraMinutes + delta).clamp(10, 720);
    });
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return "$minutes min";
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? "${h}h" : "${h}h ${m}m";
  }

  @override
  Widget build(BuildContext context) {
    final oldDuration = widget.oldEnd.difference(widget.oldStart).inMinutes;
    final newTotalDuration = oldDuration + extraMinutes;
    final newEnd = widget.oldStart.add(Duration(minutes: newTotalDuration));
    final additionalCost = extraMinutes * pricePerMinute;

    return Scaffold(
      appBar: AppBar(title: Text("Extend Ticket")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 20),
            Text("Plate: ${widget.plate}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text(
              "Original duration: ${_formatDuration(oldDuration)}",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Current end: ${DateFormat('dd/MM – HH:mm').format(widget.oldEnd)}",
            ),
            SizedBox(height: 20),

            // Selettore durata
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => _changeDuration(-60),
                  child: Text("-1h"),
                ),
                OutlinedButton(
                  onPressed: () => _changeDuration(-10),
                  child: Text("-10m"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "+${_formatDuration(extraMinutes)}",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _changeDuration(10),
                  child: Text("+10m"),
                ),
                OutlinedButton(
                  onPressed: () => _changeDuration(60),
                  child: Text("+1h"),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text("New end: ${DateFormat('dd/MM – HH:mm').format(newEnd)}"),
            SizedBox(height: 10),
            Text(
              "Additional cost: €${additionalCost.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 30),

            ElevatedButton.icon(
              icon: Icon(Icons.arrow_forward),
              label: Text("Add"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
