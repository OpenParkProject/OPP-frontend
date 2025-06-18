import 'package:flutter/material.dart';
import '../API/client.dart';
import '../login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _editMode = false;

  // User info
  String name = '', surname = '', username = '', email = '', joinDate = '';
  int numPlates = 0, numTickets = 0;

  // Editable
  String? newName, newSurname, newUsername, newEmail, newPassword, confirmPassword;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _loading = true);
    await DioClient().setAuthToken();
    try {
      final userRes = await DioClient().dio.get('/users/me');
      final carRes = await DioClient().dio.get('/users/me/cars');
      final ticketRes = await DioClient().dio.get('/users/me/tickets');

      setState(() {
        name = userRes.data['name'];
        surname = userRes.data['surname'];
        username = userRes.data['username'];
        email = userRes.data['email'];
        joinDate = userRes.data['created_at'] ?? '';
        numPlates = carRes.data.length;
        numTickets = ticketRes.data.where((t) => t['paid'] == true).length;

        newName = name;
        newSurname = surname;
        newUsername = username;
        newEmail = email;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user info: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (newPassword != null &&
        newPassword!.isNotEmpty &&
        newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      final data = {
        "name": newName ?? name,
        "surname": newSurname ?? surname,
        "username": newUsername ?? username,
        "email": newEmail ?? email,
        "password": newPassword?.isNotEmpty == true ? newPassword : "placeholder_password",
        "role": "driver"
      };

      await DioClient().dio.patch('/users/me', data: data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile updated")),
      );
      setState(() => _editMode = false);
      await _loadUserInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Account"),
        content: Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await DioClient().dio.delete('/users/me');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(24),
              child: _editMode
                  ? Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          TextFormField(
                            initialValue: newName,
                            decoration: InputDecoration(labelText: "Name"),
                            onSaved: (val) => newName = val,
                          ),
                          TextFormField(
                            initialValue: newSurname,
                            decoration: InputDecoration(labelText: "Surname"),
                            onSaved: (val) => newSurname = val,
                          ),
                          TextFormField(
                            initialValue: newUsername,
                            decoration: InputDecoration(labelText: "Username"),
                            enabled: false,
                          ),
                          TextFormField(
                            initialValue: newEmail,
                            decoration: InputDecoration(labelText: "Email"),
                            onSaved: (val) => newEmail = val,
                          ),
                          TextFormField(
                            decoration: InputDecoration(labelText: "New Password"),
                            obscureText: true,
                            onChanged: (val) => newPassword = val,
                          ),
                          TextFormField(
                            decoration: InputDecoration(labelText: "Confirm Password"),
                            obscureText: true,
                            onChanged: (val) => confirmPassword = val,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _submitUpdate,
                            child: Text("Save Changes"),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _editMode = false),
                            child: Text("Cancel"),
                          )
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage('assets/images/avatar.png'),
                            ),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("$name $surname", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text(email),
                              ],
                            )
                          ],
                        ),
                        SizedBox(height: 30),
                        _infoTile("Username", username),
                        _infoTile("Registered plates", "$numPlates"),
                        _infoTile("Total paid tickets", "$numTickets"),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => setState(() => _editMode = true),
                          child: Text("Edit Profile"),
                        ),
                        SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _deleteAccount,
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: Text("Delete Account"),
                        ),
                        SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () async {
                            DioClient().clearAuthToken();
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('access_token');
                            DioClient().clearAuthToken();

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => LoginPage()),
                              (_) => false,
                            );
                          },
                          child: Text("Log Out"),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text("$label:", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}