import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Information Setting',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UserProfilePage(),
    );
  }
}

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPlateController = TextEditingController();
  String? _selectedPlate;

  List<String> _licensePlates = [
    '粤A12345', '沪B67890', '京C54321', '川D98765', '浙E13579'
  ];

  void _addLicensePlate() {
    if (_newPlateController.text.isNotEmpty && !_licensePlates.contains(_newPlateController.text)) {
      setState(() {
        _licensePlates.add(_newPlateController.text);
        _newPlateController.clear();
      });
    }
  }

  void _removeLicensePlate(String plate) {
    setState(() {
      _licensePlates.remove(plate);
      if (_selectedPlate == plate) {
        _selectedPlate = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Information Setting'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.person),
              title: TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              trailing: Icon(Icons.edit),
            ),
            ListTile(
              leading: Icon(Icons.email),
              title: TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              trailing: Icon(Icons.edit),
            ),
            ListTile(
              leading: Icon(Icons.car_rental),
              title: Text('Please select a plate：'),
            ),
            DropdownButton<String>(
              value: _selectedPlate,
              hint: Text('Please select a plate'),
              isExpanded: true,
              items: _licensePlates.map((plate) {
                return DropdownMenuItem(
                  value: plate,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(plate),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeLicensePlate(plate),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPlate = newValue;
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: TextField(
                controller: _newPlateController,
                decoration: InputDecoration(labelText: 'Add a new plate'),
              ),
              trailing: ElevatedButton(
                onPressed: _addLicensePlate,
                child: Text('Add'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Save data'),
                      content: Text(
                        'Name: ${_nameController.text}\nEmail: ${_emailController.text}\nPlate number: ${_selectedPlate ?? '未选择'}',
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
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
