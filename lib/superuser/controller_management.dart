import 'package:flutter/material.dart';
import '../API/client.dart';
import '../admin/add_dialog.dart';
import '../utils/login_helper.dart';

class SuperuserControllerManagementPage extends StatefulWidget {
  final String username;
  const SuperuserControllerManagementPage({super.key, required this.username});

  @override
  State<SuperuserControllerManagementPage> createState() => _SuperuserControllerManagementPageState();
}

class _SuperuserControllerManagementPageState extends State<SuperuserControllerManagementPage> {
  List<Map<String, dynamic>> controllers = [];
  bool loading = true;
  String? feedback;

  @override
  void initState() {
    super.initState();
    _fetchControllers();
  }

  Future<void> _fetchControllers() async {
    setState(() {
      loading = true;
      feedback = null;
    });

    try {
      await DioClient().setAuthToken();
      final res = await DioClient().dio.get("/users");
      final all = List<Map<String, dynamic>>.from(res.data);
      setState(() {
        controllers = all.where((u) => u['role'] == 'controller').toList();
        loading = false;
      });
    } catch (_) {
      setState(() {
        feedback = "❌ Failed to load controllers";
        loading = false;
      });
    }
  }

  Future<void> _deleteController(String username) async {
    try {
      await DioClient().setAuthToken();
      await DioClient().dio.delete("/users/$username");
      setState(() => feedback = "✅ Controller deleted.");
      _fetchControllers();
    } catch (_) {
      setState(() => feedback = "❌ Failed to delete controller.");
    }
  }

  void _openAddControllerDialog() async {
    final created = await showDialog(
      context: context,
      builder: (_) => AddEditDialog(role: 'controller',
      noZoneAssignment: true),
    );

    if (created == true) _fetchControllers();
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
                : controllers.isEmpty
                    ? const Center(child: Text("No controllers found."))
                    : ListView.builder(
                        itemCount: controllers.length,
                        itemBuilder: (_, i) {
                          final c = controllers[i];
                          return Card(
                            child: ListTile(
                              title: Text(c['username']),
                              subtitle: Text("ID: ${c['id']}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.login, color: Colors.blue),
                                    tooltip: 'Login as',
                                    onPressed: () => loginAsUser(context, c['username'], 'controller'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteController(c['username']),
                                  )
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
            label: const Text("Add new controller"),
            onPressed: _openAddControllerDialog,
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
