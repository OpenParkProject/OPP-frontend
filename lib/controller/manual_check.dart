import 'package:flutter/material.dart';
import '../widgets/ticket_check_widget.dart';

class ManualCheckPage extends StatefulWidget {
  final String username;
  const ManualCheckPage({super.key, required this.username});

  @override
  State<ManualCheckPage> createState() => _ManualCheckPageState();
}

class _ManualCheckPageState extends State<ManualCheckPage> {
  final TextEditingController _plateController = TextEditingController();
  List<Map<String, dynamic>> allTickets = [];
  List<Map<String, dynamic>> activeTickets = [];
  List<Map<String, dynamic>> recentExpiredTickets = [];
  List<Map<String, dynamic>> filteredHistory = [];

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
                labelText: "Enter plate number",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text("Search Tickets"),
            ),
            const SizedBox(height: 20),
            if (_plateController.text.trim().isNotEmpty)
              Expanded(
                child: TicketCheckWidget(
                  plate: _plateController.text.trim().toUpperCase(),
                  username: widget.username,
                ),
              ),
          ],
        ),
      ),
    );
  }
}