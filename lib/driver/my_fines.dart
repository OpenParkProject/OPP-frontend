import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../API/client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyFinesPage extends StatefulWidget {
  const MyFinesPage({super.key});

  @override
  State<MyFinesPage> createState() => _MyFinesPageState();
}

class _MyFinesPageState extends State<MyFinesPage> {
  List<Map<String, dynamic>> fines = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserFines();
  }

  Future<void> _fetchUserFines() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final dio = DioClient().dio;
      final res = await dio.get('/users/me/fines');
      if (res.statusCode == 200 && res.data is List) {
        setState(() {
          fines = List<Map<String, dynamic>>.from(res.data);
        });
      } else {
        setState(() => errorMessage = "Unexpected response");
      }
    } catch (e) {
      setState(() => errorMessage = _handleError(e));
    } finally {
      setState(() => loading = false);
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

  String _formatDateTime(String iso) {
    final dt = DateTime.tryParse(iso);
    return dt != null ? DateFormat('dd MMM yyyy – HH:mm').format(dt.toLocal()) : 'Invalid date';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Fines")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                : fines.isEmpty
                    ? const Center(child: Text("You have no fines."))
                    : ListView.builder(
                        itemCount: fines.length,
                        itemBuilder: (context, index) {
                          final fine = fines[index];
                          final paid = fine['paid'] == true;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: Icon(
                                paid ? Icons.check_circle : Icons.warning_amber_rounded,
                                color: paid ? Colors.green : Colors.red,
                                size: 30,
                              ),
                              title: Text(
                                "Plate: ${fine['plate']}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text("Date: ${_formatDateTime(fine['date'])}"),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("€${fine['amount']?.toStringAsFixed(2) ?? '--'}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(paid ? "Paid" : "Unpaid",
                                      style: TextStyle(
                                        color: paid ? Colors.green : Colors.red,
                                        fontSize: 12,
                                      )),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
