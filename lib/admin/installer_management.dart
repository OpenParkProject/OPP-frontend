import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../API/client.dart';
import 'add_edit_dialog.dart'; // Assicurati di avere o creare questo file

class InstallerManagementPage extends StatefulWidget {
  const InstallerManagementPage({super.key});
  @override
  State<InstallerManagementPage> createState() => _InstallerManagementPageState();
}

class _InstallerManagementPageState extends State<InstallerManagementPage> {
  List<Map<String, dynamic>> installers = [];
  bool loading = true;
  String? feedback;

  @override
  void initState() {
    super.initState();
    _fetchInstallers();
  }

  Future<void> _fetchInstallers() async {
    setState(() {
      loading = true;
      installers = [];
      feedback = null;
    });

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      // 1. Get the logged-in admin
      final currentUserRes = await dio.get("/users/me");
      final String currentAdmin = currentUserRes.data['username'];

      // 2. Get all zones
      final zonesRes = await dio.get("/zones");
      final allZones = List<Map<String, dynamic>>.from(zonesRes.data);

      Map<String, List<Map<String, dynamic>>> groupedInstallers = {};

      // 3. For each zone, get the assigned users
      for (final zone in allZones) {
        final zid = zone['id'];
        try {
          final zoneUsersRes = await dio.get("/zones/$zid/users");
          final zoneUsers = List<Map<String, dynamic>>.from(zoneUsersRes.data);
          final zoneName = zone['name'] ?? 'Unnamed Zone';

          for (final user in zoneUsers) {
            if (user['role'] == 'installer' && (user['assigned_by'] ?? '') == currentAdmin) {
              if (!groupedInstallers.containsKey(user['username'])) {
                groupedInstallers[user['username']] = [];
              }
              groupedInstallers[user['username']]!.add({
                'zone_id': zid,
                'user_id': user['id'],
                'zone_name': zoneName,
                ...user,
              });
            }
          }
        } catch (e) {
          debugPrint("⚠️ Failed to fetch users for zone $zid: $e");
          continue; // Skip this zone and continue with the others
        }
      }

      // 5. Flatten the grouped data into a list
      List<Map<String, dynamic>> allAssignedInstallers = [];
      groupedInstallers.forEach((username, userZones) {
        allAssignedInstallers.add({
          'username': username,
          'id': userZones.first['user_id'],
          'zones': userZones,
        });
      });

      setState(() {
        installers = allAssignedInstallers;
        loading = false;
      });
    } catch (e) {
      setState(() {
        feedback = "❌ Failed to load installers.";
        loading = false;
      });
    }
  }

  Future<void> _deleteInstaller(int userId) async {
    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      await dio.delete("/users/$userId");

      setState(() => feedback = "✅ Installer deleted.");
      await _fetchInstallers();
    } catch (e) {
      setState(() => feedback = "❌ Error deleting installer.");
    }
  }

  void _openEditDialog() async {
    final updated = await showDialog(
      context: context,
      builder: (_) => AddEditDialog(role: 'installer'),
    );
    if (updated == true) _fetchInstallers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: loading
                  ? Center(child: CircularProgressIndicator())
                  : installers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "No installers found. Add one below.",
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: Icon(Icons.person_add),
                                label: Text("Add new installer"),
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
                          itemCount: installers.length,
                          itemBuilder: (_, index) {
                            final installer = installers[index];
                            return Card(
                              child: ListTile(
                                title: Text("${installer['username']}"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...installer['zones'].map((zone) {
                                      return Text("Zone: ${zone['zone_id']} - ${zone['zone_name']}");
                                    }).toList(),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteInstaller(installer['id']),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (installers.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.person_add),
                label: Text("Add new installer"),
                onPressed: () => _openEditDialog(),
              ),
            ],
            if (feedback != null && installers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(feedback!, style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
