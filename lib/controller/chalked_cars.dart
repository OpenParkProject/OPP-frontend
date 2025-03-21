import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../singleton/dio_client.dart';
import 'chalk_model.dart';

class ChalkedCarsPage extends StatefulWidget {
  final String username;
  const ChalkedCarsPage({super.key, required this.username});

  @override
  State<ChalkedCarsPage> createState() => _ChalkedCarsPageState();
}

class _ChalkedCarsPageState extends State<ChalkedCarsPage> {
  List<Chalk> chalks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchChalks();
  }

  Future<void> fetchChalks() async {
    try {
      final response = await DioClient().dio.get('/api/v1/chalk');
      setState(() {
        chalks = (response.data as List).map((e) => Chalk.fromJson(e)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      // Handle error
    }
  }

  String timeElapsed(DateTime chalkTime) {
    final now = DateTime.now();
    final diff = now.difference(chalkTime);
    return '${diff.inMinutes} min ago';
  }

  Future<void> verifyChalk(int id, bool stillPresent) async {
    await DioClient().dio.patch('/api/v1/chalk/$id/verify', data: {
      'still_present': stillPresent,
    });
    fetchChalks(); // refresh
  }

  void showAddChalkDialog() {
    final plateController = TextEditingController();
    final reasonController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Chalk"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: plateController, decoration: const InputDecoration(labelText: "Plate")),
            TextField(controller: reasonController, decoration: const InputDecoration(labelText: "Reason")),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: "Notes")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await DioClient().dio.post('/api/v1/chalk', data: {
                'plate': plateController.text,
                'controller_username': widget.username,
                'reason': reasonController.text,
                'notes': notesController.text,
              });
              Navigator.pop(context);
              fetchChalks();
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: chalks.length,
              itemBuilder: (_, i) {
                final chalk = chalks[i];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    title: Text(chalk.plate, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "Chalked: ${DateFormat.Hm().format(chalk.chalkTime)} (${timeElapsed(chalk.chalkTime)})\n"
                      "Reason (optional): ${chalk.reason ?? '-'}\nNotes (optional): ${chalk.notes ?? '-'}",
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => verifyChalk(chalk.id, true),
                          child: const Text("✔ Still here"),
                        ),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: () => verifyChalk(chalk.id, false),
                          child: const Text("✘ Gone"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddChalkDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
