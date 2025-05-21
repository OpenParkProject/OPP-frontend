import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../singleton/dio_client.dart';

class ManualCheckPage extends StatefulWidget {
  const ManualCheckPage({super.key});

  @override
  State<ManualCheckPage> createState() => _ManualCheckPageState();
}

class _ManualCheckPageState extends State<ManualCheckPage> {
  final TextEditingController _plateController = TextEditingController();
  List<Map<String, dynamic>> tickets = [];
  bool _loading = false;
  String? _errorMessage;

  Future<void> _fetchTickets() async {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isEmpty) return;

    setState(() {
      _loading = true;
      tickets.clear();
      _errorMessage = null;
    });

    try {
      final dio = DioClient().dio;
      final response = await dio.get('/cars/$plate/tickets');
      final data = response.data;

      if (data is List) {
        setState(() {
          tickets = List<Map<String, dynamic>>.from(data);
        });
      } else {
        setState(() {
          _errorMessage = "Risposta inattesa dal server.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Errore: ${_handleError(e)}";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _handleError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('detail')) return data['detail'];
      return error.message ?? "Errore di rete";
    }
    return error.toString();
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
                labelText: "Inserisci la targa",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _fetchTickets(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchTickets,
              child: const Text("Cerca Ticket"),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const CircularProgressIndicator()
            else if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red))
            else if (tickets.isEmpty)
              const Text("Nessun ticket trovato")
            else
              Expanded(
                child: ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    final start = ticket['start_date'] ?? '';
                    final end = ticket['end_date'] ?? '';
                    final paid = ticket['paid'] == true;
                    final valid = DateTime.tryParse(end)?.isAfter(DateTime.now()) ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text("Dal: $start\nAl: $end"),
                        subtitle: Text("Stato: ${valid ? 'Valido' : 'Scaduto'}"),
                        trailing: Icon(
                          paid ? Icons.check_circle : Icons.warning,
                          color: paid ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
