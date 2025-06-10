import 'package:flutter/material.dart';
import '../API/client.dart';
import 'add_edit_dialog.dart';

class ControllerManagementPage extends StatefulWidget {
  const ControllerManagementPage({super.key});
  @override
  State<ControllerManagementPage> createState() => _ControllerManagementPageState();
}

class _ControllerManagementPageState extends State<ControllerManagementPage> {
  List<Map<String, dynamic>> controllers = [];
  bool loading = true;
  String? feedback;
  String? currentAdmin;

  @override
  void initState() {
    super.initState();
    _fetchControllers();
  }

  Future<void> _fetchControllers() async {
    setState(() {
      String? currentAdmin;
      loading = true;
      controllers = [];
      feedback = null;
    });

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      // 1. Get the logged-in admin
      final currentUserRes = await dio.get("/users/me");
      final String admin = currentUserRes.data['username'];
      setState(() {
        currentAdmin = admin;
      });


      // 2. Get all zones
      final zonesRes = await dio.get("/zones");
      final allZones = List<Map<String, dynamic>>.from(zonesRes.data);

      Map<String, List<Map<String, dynamic>>> groupedControllers = {};

      // 3. For each zone, get the assigned users
      for (final zone in allZones) {
        final zid = zone['id'];
        try {
          final zoneUsersRes = await dio.get("/zones/$zid/users");
          final zoneUsers = List<Map<String, dynamic>>.from(zoneUsersRes.data);
          final zoneName = zone['name'] ?? 'Unnamed Zone';

          for (final user in zoneUsers) {
            if (user['role'] == 'controller' && (user['assigned_by'] ?? '') == currentAdmin) {
              if (!groupedControllers.containsKey(user['username'])) {
                groupedControllers[user['username']] = [];
              }
              groupedControllers[user['username']]!.add({
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
      List<Map<String, dynamic>> allAssignedControllers = [];
      groupedControllers.forEach((username, userZones) {
        allAssignedControllers.add({
          'username': username,
          'id': userZones.first['user_id'],
          'zones': userZones,
        });
      });

      setState(() {
        controllers = allAssignedControllers;
        loading = false;
      });
    } catch (e) {
      setState(() {
        feedback = "❌ Failed to load controllers.";
        loading = false;
      });
    }
  }

  Future<void> _deleteController(int zoneUserId, String username, List<dynamic> zones) async {
    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      // Elimina da tutte le zone
      for (final zone in zones) {
        final zoneId = zone['zone_id'];
        try {
          await dio.delete("/zones/$zoneId/users/$username");
          debugPrint("✅ Removed from zone $zoneId");
        } catch (e) {
          debugPrint("⚠️ Removal from zone $zoneId failed: $e");
        }
      }

      // Recupera il vero userId dal sistema auth
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
          debugPrint("✅ User $username deleted from auth db");
        } else {
          debugPrint("⚠️ No user found for $username");
        }
      } catch (e) {
        debugPrint("⚠️ Error: $e");
      }

      setState(() => feedback = "✅ Controller deleted from zones and system.");
      await _fetchControllers();
    } catch (e) {
      setState(() => feedback = "❌ Error deleting controller.");
      debugPrint("❌ General Error: $e");
    }
  }

  void _openEditDialog() async {
    final updated = await showDialog(
      context: context,
      builder: (_) => AddEditDialog(role: 'controller'),
    );
    if (updated == true) _fetchControllers();
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
                  "Controllers created by admin $currentAdmin",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: loading
                  ? Center(child: CircularProgressIndicator())
                  : controllers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "No controllers found. Add one below.",
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: Icon(Icons.person_add),
                                label: Text("Add new controller"),
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
                          itemCount: controllers.length,
                          itemBuilder: (_, index) {
                            final controller = controllers[index];
                            return Card(
                              child: ListTile(
                                title: Text("${controller['username']}"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...controller['zones'].map((zone) {
                                      return Text("Zone: ${zone['zone_id']} - ${zone['zone_name']}");
                                    }).toList(),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                     onPressed: () => _deleteController(
                                      controller['id'],
                                      controller['username'],
                                      controller['zones'],
                                    ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (controllers.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.person_add),
                label: Text("Add new controller"),
                onPressed: () => _openEditDialog(),
              ),
            ],
            if (feedback != null && controllers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(feedback!, style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
