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
  String? _tempUsername;
  String? _tempPassword;

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

  Future<void> _deleteAdmin(String username) async {
    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;
      await dio.delete("/users/$username");

      setState(() => feedback = "✅ Admin deleted.");
      _fetchAdmins();
    } catch (e) {
      setState(() => feedback = "❌ Failed to delete admin.");
    }
  }

  void _openAddAdminDialog() async {
    final created = await showDialog(
      context: context,
      builder: (_) => AddEditDialog(
        role: 'admin',
        noZoneAssignment: true,
        onCredentialsSaved: (username, password) {
          _tempUsername = username;
          _tempPassword = password;
        },
      ),
    );

    if (created == true) {
      await _fetchAdmins();
      if (_tempUsername != null && _tempPassword != null) {
        final loginNow = await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Login as $_tempUsername?"),
            content: Text("Do you want to log in immediately as the new admin?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text("No")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Yes")),
            ],
          ),
        );

        if (loginNow == true) {
          _loginAsNewAdmin(_tempUsername!, _tempPassword!);
        }

        _tempUsername = null;
        _tempPassword = null;
      }
    }
  }

  Future<void> _loginAsNewAdmin(String username, String password) async {
    try {
      final dio = DioClient().dio;
      final response = await dio.post('/login', data: {
        'username': username,
        'password': password,
      });

      final token = response.data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      DioClient().dio.options.headers['Authorization'] = 'Bearer $token';

      try {
        final zonesResponse = await dio.get('/zones/me');
        final zoneListRaw = zonesResponse.data;

        if (zoneListRaw is List) {
          final zoneList = List<Map<String, dynamic>>.from(zoneListRaw);
          final zoneIds = zoneList.map((z) => z['id'].toString()).toList();
          final zoneNames = zoneList.map((z) => z['name'].toString()).toList();

          await prefs.setStringList('zone_ids', zoneIds);
          await prefs.setStringList('zone_names', zoneNames);
        } else {
          debugPrint("/zones/me returned null or unexpected format.");
          await prefs.setStringList('zone_ids', []);
          await prefs.setStringList('zone_names', []);
        }
      } catch (e) {
        debugPrint("Failed to load /zones/me: $e");
        await prefs.setStringList('zone_ids', []);
        await prefs.setStringList('zone_names', []);
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AdminLayout(username: username)),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Login as $username failed")),
      );
    }
  }

  String _formatSubtitle(Map<String, dynamic> admin) {
    final email = admin['email'] ?? "";
    final id = admin['id'] ?? "-";

    final match = RegExp(r'^(\d{13})@').firstMatch(email);
    if (match != null) {
      final ts = int.parse(match.group(1)!);
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      final formatted = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
      return "Admin Id :$id – Created on: $formatted";
    }

    return "#$id";
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
                    ? Center(child: Text("No admins found."))
                    : ListView.builder(
                        itemCount: admins.length,
                        itemBuilder: (_, index) {
                          final admin = admins[index];
                          return Card(
                            child: ListTile(
                              title: Text(admin['username']),
                              subtitle: Text(_formatSubtitle(admin)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteAdmin(admin['username']),
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
