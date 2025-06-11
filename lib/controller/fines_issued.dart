import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../API/client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinesIssuedPage extends StatefulWidget {
  const FinesIssuedPage({super.key});

  @override
  State<FinesIssuedPage> createState() => _FinesIssuedPageState();
}

class _FinesIssuedPageState extends State<FinesIssuedPage> {
  final TextEditingController _plateController = TextEditingController();
  List<Map<String, dynamic>> fines = [];
  bool loading = false;
  String? errorMessage;
  DateTime selectedDate = DateTime.now();
  bool hasSearched = false;

  @override
  void initState() {
    super.initState();
    _fetchFines(); // preload daily fines
  }

  Future<void> _fetchFines() async {
    setState(() {
      loading = true;
      errorMessage = null;
      fines = [];
      hasSearched = true;
    });

    final plate = _plateController.text.trim().toUpperCase();
    final targetDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      final prefs = await SharedPreferences.getInstance();
      final zoneIds = prefs.getStringList("zone_ids");
      if (zoneIds == null || zoneIds.isEmpty) {
        setState(() {
          errorMessage = "No zone permissions found for this controller.";
          loading = false;
        });
        return;
      }

      final dio = DioClient().dio;
      final List<Map<String, dynamic>> allFines = [];

      for (final zid in zoneIds) {
        final res = await dio.get('/zones/$zid/fines');
        if (res.statusCode == 200 && res.data is List) {
          for (final fine in res.data) {
            final m = Map<String, dynamic>.from(fine);
            if (plate.isNotEmpty && (m['plate'] ?? '').toString().toUpperCase() != plate) continue;

            final dateStr = m['date'];
            if (dateStr != null) {
              final parsed = DateTime.tryParse(dateStr);
              if (parsed != null &&
                  (plate.isNotEmpty || DateFormat('yyyy-MM-dd').format(parsed.toLocal()) == targetDate)) {
                allFines.add(m);
              }
            }
          }
        }
      }

      setState(() {
        fines = allFines;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error: ${_handleError(e)}";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  String _handleError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('detail')) return data['detail'];
      return error.message ?? "Network error";
    }
    return error.toString();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      _fetchFines();
    }
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy – HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy').format(selectedDate);
    final plate = _plateController.text.trim().toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text("Select Date: $formattedDate"),
                  onPressed: _selectDate,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text("Search by Plate"),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        String tempPlate = "";
                        return AlertDialog(
                          title: const Text("Search by Plate"),
                          content: TextField(
                            autofocus: true,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(labelText: "Plate"),
                            onChanged: (value) => tempPlate = value.toUpperCase(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _plateController.text = tempPlate;
                                _fetchFines();
                              },
                              child: const Text("Search"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reset Filters"),
                  onPressed: () {
                    setState(() {
                      _plateController.clear();
                      selectedDate = DateTime.now();
                    });
                    _fetchFines();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (hasSearched)
            Text(
              plate.isNotEmpty
                ? "Showing all fines for plate $plate"
                : "Showing fines for $formattedDate",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
          else if (fines.isEmpty)
            const Center(child: Text("No fines found."))
          else
            Expanded(
              child: ListView.builder(
                itemCount: fines.length,
                itemBuilder: (context, index) {
                  final fine = fines[index];
                  final date = DateTime.tryParse(fine['date'] ?? '') ?? DateTime.now();
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fine['plate'] ?? 'UNKNOWN',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Text(
                                  "Date: ${_formatDateTime(date)}",
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "€${(fine['amount'] as num).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fine['paid'] == true ? "Paid" : "Unpaid",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: fine['paid'] == true ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}