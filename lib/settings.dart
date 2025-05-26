import 'package:flutter/material.dart';


class UserProfilePage extends StatefulWidget {
  UserProfilePage({super.key});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPlateController = TextEditingController();
  String? _selectedPlate;

  final List<String> _licensePlates = [
    'BA12345', 'CB67890', 'JC54321', 'CD98765', 'ZE13579'
  ];

  List<String> get licensePlates =>_licensePlates;

  void increment() {
    //notifyListeners(); // 通知监听者更新 UI
  }

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
              title: DropdownButton<String>(
                value: _selectedPlate,
                hint: Text('Select a plate'),
                isExpanded: true,
                items: _licensePlates.map((plate) {
                  return DropdownMenuItem(
                    value: plate,
                    child: Row(
                      //mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            ),

            ListTile(
              leading: Icon(Icons.add_circle),
              title: TextField(
                controller: _newPlateController,
                decoration: InputDecoration(labelText: 'Add a new plate'),
              ),
              trailing: ElevatedButton(
                onPressed: _addLicensePlate,
                child: Icon(Icons.add),
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
