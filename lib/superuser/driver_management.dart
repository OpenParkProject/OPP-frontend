import 'package:flutter/material.dart';
import '../API/client.dart';
import '../admin/add_dialog.dart';
import '../utils/login_helper.dart';

class SuperuserDriverManagementPage extends StatefulWidget {
  final String username;
  const SuperuserDriverManagementPage({super.key, required this.username});

  @override
  State<SuperuserDriverManagementPage> createState() => _SuperuserDriverManagementPageState();
}

class _SuperuserDriverManagementPageState extends State<SuperuserDriverManagementPage> {
  List<Map<String, dynamic>> drivers = [];
  bool loading = true;
  String? feedback;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    setState(() {
      loading = true;
      feedback = null;
    });

    try {
      await DioClient().setAuthToken();
      final res = await DioClient().dio.get("/users");
      final all = List<Map<String, dynamic>>.from(res.data);
      setState(() {
        drivers = all.where((u) => u['role'] == 'driver').toList();
        loading = false;
      });
    } catch (_) {
      setState(() {
        feedback = "❌ Failed to load drivers";
        loading = false;
      });
    }
  }

  Future<void> _deleteDriver(String username) async {
    try {
      await DioClient().setAuthToken();
      await DioClient().dio.delete("/users/$username");
      setState(() => feedback = "✅ Driver deleted.");
      _fetchDrivers();
    } catch (_) {
      setState(() => feedback = "❌ Failed to delete driver.");
    }
  }

  void _openAddDriverDialog() async {
    final created = await showDialog(
      context: context,
      builder: (_) => AddEditDialog(
        role: 'driver',
        noZoneAssignment: true,
      ),
    );

    if (created == true) _fetchDrivers();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : drivers.isEmpty
                    ? const Center(child: Text("No drivers found."))
                    : ListView.builder(
                        itemCount: drivers.length,
                        itemBuilder: (_, i) {
                          final d = drivers[i];
                          return Card(
                            child: ListTile(
                              title: Text(d['username']),
                              subtitle: Text("ID: ${d['id']}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.login, color: Colors.blue),
                                    tooltip: 'Login as ${d['username']}',
                                    onPressed: () => loginAsUser(context, d['username'], 'admin'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteDriver(d['username']),
                                  ),
                                ],
                              ),

                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text("Add new driver"),
            onPressed: _openAddDriverDialog,
          ),
          if (feedback != null) ...[
            const SizedBox(height: 12),
            Text(feedback!, style: const TextStyle(color: Colors.red)),
          ]
        ],
      ),
    );
  }
}
