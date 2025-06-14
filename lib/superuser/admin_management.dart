import 'package:flutter/material.dart';
import '../API/client.dart';
import '../admin/add_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin/admin_layout.dart';

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

  Future<void> _loginAsAdmin(String username) async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Login as $username?"),
        content: Text("You will log out as superuser and enter the admin interface."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Login")),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString("admin_pw_$username");

      if (savedPassword == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No saved password for $username")),
        );
        return;
      }

      final dio = DioClient().dio;
      final response = await dio.post('/login', data: {
        'username': username,
        'password': savedPassword,
      });

      final token = response.data['access_token'];
      await prefs.setString('access_token', token);
      DioClient().dio.options.headers['Authorization'] = 'Bearer $token';

      // Recupera le zone
      final zonesResponse = await dio.get('/zones/me');
      final zoneList = zonesResponse.data as List<dynamic>;
      final zoneIds = zoneList.map((z) => z['id'].toString()).toList();
      final zoneNames = zoneList.map((z) => z['name'].toString()).toList();

      await prefs.setStringList('zone_ids', zoneIds);
      await prefs.setStringList('zone_names', zoneNames);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AdminLayout(username: username)),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Login as $username failed")),
      );
    }
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.login, color: Colors.blue),
                                    tooltip: "Login as ${admin['username']}",
                                    onPressed: () => _loginAsAdmin(admin['username']),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteAdmin(admin['id']),
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
