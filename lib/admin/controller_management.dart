import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../API/client.dart';
import 'add_edit_controller_dialog.dart';

class ControllerManagementPage extends StatefulWidget {
  const ControllerManagementPage({super.key});
  @override
  State<ControllerManagementPage> createState() => _ControllerManagementPageState();
}

class _ControllerManagementPageState extends State<ControllerManagementPage> {
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
      controllers = [];
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

      Map<String, List<Map<String, dynamic>>> groupedControllers = {};

      // 3. For each zone, get the assigned users
      for (final zone in allZones) {
        final zid = zone['id'];
        final zoneUsersRes = await dio.get("/zones/$zid/users");
        final zoneUsers = List<Map<String, dynamic>>.from(zoneUsersRes.data);
        final zoneDetailsRes = await dio.get("/zones/$zid");
        final zoneName = zoneDetailsRes.data['name'];

        // 4. Filter controllers assigned by the current admin
        for (final user in zoneUsers) {
          if (user['role'] == 'controller' && (user['assigned_by'] ?? '') == currentAdmin) {
            // Group by username
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
      }

      // 5. Flatten the grouped data into a list
      List<Map<String, dynamic>> allAssignedControllers = [];
      groupedControllers.forEach((username, userZones) {
        allAssignedControllers.add({
          'username': username,
          'id': userZones.first['user_id'],
          'zones': userZones,
           'password': userZones.first['password'] ?? '********',
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
  
  Future<void> _deleteController(int userId) async {
    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      await dio.delete("/users/$userId");

      setState(() => feedback = "✅ Controller deleted.");
      await _fetchControllers();
    } catch (e) {
      setState(() => feedback = "❌ Error deleting controller.");
    }
  }

  void _openEditDialog() async {
    final updated = await showDialog(
      context: context,
      builder: (_) => AddEditControllerDialog(),
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
                                      onPressed: () => _deleteController(controller['id']),
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
