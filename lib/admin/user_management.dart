import 'package:flutter/material.dart';

import '../singleton/dio_client.dart';

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> {
  List<Map<String, String>> users = [];
  bool loadingUsers = true;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      await DioClient().setAuthToken();
      final response = await DioClient().dio.get("/users");

      final fetchedUsers =
          (response.data as List)
              .map<Map<String, String>>(
                (user) => {
                  "name": "${user["name"] ?? ""}",
                  "surname": "${user["surname"] ?? ""}",
                  "username": "${user["username"] ?? ""}",
                  "email": "${user["email"] ?? ""}",
                  "role": "${user["role"] ?? ""}",
                },
              )
              .toList();

      setState(() {
        users = fetchedUsers;
        loadingUsers = false;
      });
    } catch (e) {
      setState(() {
        loadingUsers = false;
        _feedbackMessage = "❌ Failed to load users.";
      });
    }
  }

  Future<void> _deleteAllUsers() async {
    try {
      await DioClient().setAuthToken();
      await DioClient().dio.delete("/users");

      setState(() {
        _feedbackMessage = "✅ All users deleted.";
      });

      await _fetchUsers();
    } catch (e) {
      setState(() {
        _feedbackMessage = "❌ Failed to delete all users.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Management")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (loadingUsers)
              CircularProgressIndicator()
            else if (users.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Registered Users:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete_forever),
                    label: Text("Delete All"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text("Confirm Delete"),
                              content: Text(
                                "Are you sure you want to delete ALL users? This cannot be undone.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("Delete All"),
                                ),
                              ],
                            ),
                      );

                      if (confirm == true) {
                        await _deleteAllUsers();
                      }
                    },
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text(user["username"] ?? ''),
                      subtitle: Text(
                        "${user["name"]} ${user["surname"]} (${user["role"]})",
                      ),
                    );
                  },
                ),
              ),
              Divider(),
            ],
            if (_feedbackMessage != null) ...[
              SizedBox(height: 16),
              Text(_feedbackMessage!, style: TextStyle(color: Colors.blue)),
            ],
          ],
        ),
      ),
    );
  }
}
