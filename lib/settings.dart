import 'package:flutter/material.dart';


class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _selectedPlate;

  final List<String> _licensePlates = [
    '粤A12345', '沪B67890', '京C54321', '川D98765', '浙E13579'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal information'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.person),
              title: TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name and Surname'),
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.email),
              title: TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.car_repair),
              title: Text('Choose your car plate'),
              subtitle:DropdownButton<String>(
                value: _selectedPlate,
                hint: Text('Choose your car plate'),
                isExpanded: true,
                items: _licensePlates.map((plate) {
                  return DropdownMenuItem(
                    value: plate,
                    child: Text(plate),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPlate = newValue;
                  });
                },
              ),
            ),

            SizedBox(height: 480),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Save'),
                      content: Text(
                        'Name and Surname: ${_nameController.text}\nE-mail: ${_emailController.text}\nCar Plate: ${_selectedPlate ?? '未选择'}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Confirm'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('save'),
            ),
          ],
        ),
      ),
    );
  }
}
