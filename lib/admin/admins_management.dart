import 'package:flutter/material.dart';
import '../API/client.dart';
import 'add_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAdminManagementPage extends StatefulWidget {
  const AdminAdminManagementPage({super.key});
  @override
  State<AdminAdminManagementPage> createState() => _AdminAdminManagementPageState();
}

class _AdminAdminManagementPageState extends State<AdminAdminManagementPage> {
  List<Map<String, dynamic>> admins = [];
  bool loading = true;
  String? feedback;
  String? currentAdmin;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    setState(() {
      loading = true;
      admins = [];
      feedback = null;
    });

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      final currentUserRes = await dio.get("/users/me");
      final String admin = currentUserRes.data['username'];
      setState(() {
        currentAdmin = admin;
      });

      final prefs = await SharedPreferences.getInstance();
      final zoneIds = prefs.getStringList('zone_ids') ?? [];
      final zoneNames = prefs.getStringList('zone_names') ?? [];

      Map<String, List<Map<String, dynamic>>> groupedAdmins = {};

      for (int i = 0; i < zoneIds.length; i++) {
        final zid = int.tryParse(zoneIds[i]);
        if (zid == null) continue;

        final zoneName = zoneNames.length > i ? zoneNames[i] : 'Unnamed Zone';

        try {
          final zoneUsersRes = await dio.get("/zones/$zid/users");
          final zoneUsers = List<Map<String, dynamic>>.from(zoneUsersRes.data);

          for (final user in zoneUsers) {
            if (user['role'] == 'admin' && user['assigned_by'] == admin && user['username'] != admin) {
              if (!groupedAdmins.containsKey(user['username'])) {
                groupedAdmins[user['username']] = [];
              }
              groupedAdmins[user['username']]!.add({
                'zone_id': zid,
                'user_id': user['id'],
                'zone_name': zoneName,
                ...user,
              });
            }
          }
        } catch (_) {}
      }

      List<Map<String, dynamic>> allAssignedAdmins = [];
      groupedAdmins.forEach((username, userZones) {
        allAssignedAdmins.add({
          'username': username,
          'id': userZones.first['user_id'],
          'zones': userZones,
        });
      });

      setState(() {
        admins = allAssignedAdmins;
        loading = false;
      });
    } catch (e) {
      setState(() {
        feedback = "❌ Failed to load admins.";
        loading = false;
      });
    }
  }

  Future<void> _deleteAdmin(int id, String username, List<dynamic> zones) async {
    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      for (final zone in zones) {
        final zoneId = zone['zone_id'];
        try {
          await dio.delete("/zones/$zoneId/users/$username");
        } catch (_) {}
      }

      try {
        final allUsersRes = await dio.get("/users");
        final allUsers = List<Map<String, dynamic>>.from(allUsersRes.data);
        final authUser = allUsers.firstWhere(
          (u) => u['username'] == username,
          orElse: () => {},
        );

        if (authUser.isNotEmpty) {
          final authUserId = authUser['id'];
          await dio.delete("/users/$authUserId");
        }
      } catch (_) {}

      setState(() => feedback = "✅ Admin deleted.");
      await _fetchAdmins();
    } catch (e) {
      setState(() => feedback = "❌ Error deleting admin.");
    }
  }

  void _openEditDialog() async {
    final updated = await showDialog(
      context: context,
      builder: (_) => AddEditDialog(role: 'admin'),
    );
    if (updated == true) _fetchAdmins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (currentAdmin != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Admins created by $currentAdmin",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: loading
                  ? Center(child: CircularProgressIndicator())
                  : admins.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("No admins found.", style: TextStyle(fontSize: 16)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: Icon(Icons.person_add),
                                label: Text("Add new admin"),
                                onPressed: () => _openEditDialog(),
                              ),
                              if (feedback != null) ...[
                                const SizedBox(height: 12),
                                Text(feedback!, style: TextStyle(color: Colors.red)),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: admins.length,
                          itemBuilder: (_, index) {
                            final admin = admins[index];
                            return Card(
                              child: ListTile(
                                title: Text("${admin['username']}"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...admin['zones'].map((zone) {
                                      return Text("Zone: ${zone['zone_id']} - ${zone['zone_name']}");
                                    }).toList(),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteAdmin(
                                    admin['id'],
                                    admin['username'],
                                    admin['zones'],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (admins.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.person_add),
                label: Text("Add new admin"),
                onPressed: () => _openEditDialog(),
              ),
            ],
            if (feedback != null && admins.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(feedback!, style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
