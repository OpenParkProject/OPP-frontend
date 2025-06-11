import 'package:flutter/material.dart';
import '../API/client.dart';
import '../admin/add_edit_dialog.dart';

class SuperuserAdminManagementPage extends StatefulWidget {
  final String username;
  const SuperuserAdminManagementPage({super.key, required this.username});

  @override
  State<SuperuserAdminManagementPage> createState() => _SuperuserAdminManagementPageState();
}

class _SuperuserAdminManagementPageState extends State<SuperuserAdminManagementPage> {
  List<Map<String, dynamic>> admins = [];
  bool loading = true;
  String? feedback;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    setState(() {
      loading = true;
      feedback = null;
    });

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;
      final res = await dio.get("/users");
      final all = List<Map<String, dynamic>>.from(res.data);

      setState(() {
        admins = all.where((u) => u['role'] == 'admin').toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        feedback = "❌ Failed to load admins";
        loading = false;
      });
    }
  }

  Future<void> _deleteAdmin(int id) async {
    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;
      await dio.delete("/users/$id");

      setState(() => feedback = "✅ Admin deleted.");
      _fetchAdmins();
    } catch (e) {
      setState(() => feedback = "❌ Failed to delete admin.");
    }
  }

  void _openAddAdminDialog() async {
    final created = await showDialog(
      context: context,
      builder: (_) => AddEditDialog(role: 'admin', noZoneAssignment: true),
    );
    if (created == true) _fetchAdmins();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Admin Users",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator())
                : admins.isEmpty
                    ? Center(
                        child: Text("No admins found."),
                      )
                    : ListView.builder(
                        itemCount: admins.length,
                        itemBuilder: (_, index) {
                          final admin = admins[index];
                          return Card(
                            child: ListTile(
                              title: Text("${admin['username']}"),
                              subtitle: Text(admin['email'] ?? ""),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteAdmin(admin['id']),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.person_add),
            label: Text("Add new admin"),
            onPressed: _openAddAdminDialog,
          ),
          if (feedback != null) ...[
            const SizedBox(height: 12),
            Text(feedback!, style: TextStyle(color: Colors.red)),
          ]
        ],
      ),
    );
  }
}
