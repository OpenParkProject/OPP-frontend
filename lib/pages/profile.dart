import 'package:flutter/material.dart';
import 'login.dart';

class ProfilePage extends StatelessWidget {
  final String username;

  const ProfilePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 30, backgroundImage: AssetImage('assets/images/avatar.png')),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username.isNotEmpty ? username : "Guest", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("$username@example.com"),
                ],
              )
            ],
          ),
          SizedBox(height: 30),
          Text("My Account Information", style: TextStyle(color: Colors.grey)),
          ListTile(title: Text("Change Password"), trailing: Icon(Icons.arrow_forward_ios)),
          ListTile(title: Text("Edit Profile"), trailing: Icon(Icons.arrow_forward_ios)),
          Divider(),
          Text("Account Settings", style: TextStyle(color: Colors.grey)),
          SwitchListTile(
            title: Text("Dark Mode"),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (_) {}, // mock, lo vedremo in seguito
          ),
          SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginPage()), (_) => false);
              },
              child: Text("Log Out"),
            ),
          )
        ],
      ),
    );
  }
}
