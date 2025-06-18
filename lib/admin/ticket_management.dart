import 'package:flutter/material.dart';

import '../API/client.dart';

class TicketManagementPage extends StatefulWidget {
  const TicketManagementPage({super.key});

  @override
  State<TicketManagementPage> createState() => _TicketManagementPageState();
}

class _TicketManagementPageState extends State<TicketManagementPage> {
  final TextEditingController _idController = TextEditingController();
  List<dynamic> _tickets = [];
  Map<String, dynamic>? _singleTicket;
  bool _isLoading = false;

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidId(String input) => int.tryParse(input) != null;

  Future<void> _getTickets() async {
    setState(() => _isLoading = true);
    final id = _idController.text.trim();
    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      if (id.isEmpty) {
        final res = await dio.get('/tickets');
        setState(() {
          _tickets = res.data;
          _singleTicket = null;
        });
      } else if (_isValidId(id)) {
        final res = await dio.get('/tickets/$id');
        setState(() {
          _singleTicket = res.data;
          _tickets = [];
        });
      } else {
        _showSnackbar('Invalid ID');
      }
    } catch (_) {
      _showSnackbar('Error fetching ticket(s)');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteTicket() async {
    final id = _idController.text.trim();
    if (!_isValidId(id)) {
      _showSnackbar('Invalid ID');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await DioClient().setAuthToken();
      final res = await DioClient().dio.delete('/tickets/$id');
      if (res.statusCode == 200) {
        _showSnackbar('Ticket deleted');
        _getTickets();
      } else {
        _showSnackbar('Failed to delete');
      }
    } catch (_) {
      _showSnackbar('Error deleting ticket');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _editTicket() async {
    final id = _idController.text.trim();
    if (!_isValidId(id)) {
      _showSnackbar('Invalid ID');
      return;
    }

    Map<String, TextEditingController> fields = {
      'plate': TextEditingController(),
      'price': TextEditingController(),
      'paid': TextEditingController(),
    };

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Ticket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                fields.entries.map((entry) {
                  return TextField(
                    controller: entry.value,
                    decoration: InputDecoration(labelText: entry.key),
                  );
                }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await DioClient().setAuthToken();
                  final updatedData = {
                    'plate': fields['plate']!.text.trim(),
                    'price':
                        double.tryParse(fields['price']!.text.trim()) ?? 0.0,
                    'paid': fields['paid']!.text.trim().toLowerCase() == 'true',
                  };

                  final res = await DioClient().dio.patch(
                    '/tickets/$id',
                    data: updatedData,
                  );
                  if (res.statusCode == 200) {
                    _showSnackbar('Updated');
                    Navigator.pop(context);
                    _getTickets();
                  } else {
                    _showSnackbar('Update failed');
                  }
                } catch (_) {
                  _showSnackbar('Error updating ticket');
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    return ExpansionTile(
      title: Text('Ticket ID: ${ticket['id']}'),
      children: [
        ListTile(title: Text('Plate: ${ticket['plate']}')),
        ListTile(title: Text('Start: ${ticket['start_date']}')),
        ListTile(title: Text('End: ${ticket['end_date']}')),
        ListTile(title: Text('Price: ${ticket['price']}')),
        ListTile(title: Text('Paid: ${ticket['paid']}')),
        ListTile(title: Text('Created: ${ticket['creation_time']}')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputId = _idController.text.trim();
    final validId = _isValidId(inputId);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText:
                    'Please enter ticket ID (or leave empty for all tickets)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _getTickets,
                  child: const Text('Get'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: validId ? _deleteTicket : null,
                  child: const Text('Delete'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: validId ? _editTicket : null,
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                        children: [
                          if (_singleTicket != null)
                            _buildTicketCard(_singleTicket!),
                          ..._tickets
                              .map<Widget>(
                                (ticket) => _buildTicketCard(
                                  ticket as Map<String, dynamic>,
                                ),
                              )
                              .toList(),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
