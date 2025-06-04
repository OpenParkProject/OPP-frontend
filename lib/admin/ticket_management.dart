import 'package:flutter/material.dart';
import 'package:openpark/admin/utils/url_dao.dart';

import '../singleton/dio_client.dart';

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

  bool _isValidId(String input) {
    return int.tryParse(input) != null;
  }

  Future<void> _getTickets() async {
    setState(() => _isLoading = true);
    final id = _idController.text.trim();

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      if (id.isEmpty) {
        final response = await dio.get(ticketUrl);
        setState(() {
          _tickets = response.data;
          _singleTicket = null;
        });
      } else if (_isValidId(id)) {
        final response = await dio.get('$ticketUrl/$id');
        setState(() {
          _singleTicket = response.data;
          _tickets = [];
        });
      } else {
        _showSnackbar('Please enter a valid numeric ID');
      }
    } catch (e) {
      _showSnackbar('Error fetching ticket(s)');
    }

    setState(() => _isLoading = false);
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Please enter ticket ID',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _getTickets,
              child: const Text('Get Tickets'),
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
