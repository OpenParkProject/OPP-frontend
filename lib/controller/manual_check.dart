import 'package:flutter/material.dart';
import '../widgets/ticket_check_widget.dart';

class ManualCheckPage extends StatefulWidget {
  final String username;
  const ManualCheckPage({
    super.key, 
    required this.username,
    });

  @override
  State<ManualCheckPage> createState() => _ManualCheckPageState();
}

class _ManualCheckPageState extends State<ManualCheckPage> {
  final TextEditingController _plateController = TextEditingController();
  String? currentPlate;
  Key? currentKey;

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
              onPressed: () {
                final plate = _plateController.text.trim().toUpperCase();
                if (plate.isNotEmpty) {
                  setState(() {
                    currentPlate = plate;
                    currentKey = ValueKey(plate); // cambia la key ogni volta
                  });
                }
              },
              child: const Text("Search Tickets"),
            ),
            const SizedBox(height: 1),
            if (currentPlate != null)
              Expanded(
                child: TicketCheckWidget(
                  key: currentKey,
                  plate: currentPlate!,
                  username: widget.username,
                ),
              ),
          ],
        ),
      ),
    );
  }
}