import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../API/client.dart';

class ControllerManagementPage extends StatefulWidget {
  const ControllerManagementPage({super.key});

  @override
  State<ControllerManagementPage> createState() =>
      _ControllerManagementPageState();
}

// 省略 import 和 class 定义部分...

class _ControllerManagementPageState extends State<ControllerManagementPage> {
  final TextEditingController _idController = TextEditingController();
  List<dynamic> _users = [];
  Map<String, dynamic>? _singleUser;
  bool _isLoading = false;

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidId(String input) {
    return int.tryParse(input) != null;
  }

  Future<void> _getUsers() async {
    setState(() => _isLoading = true);
    final id = _idController.text.trim();

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      if (id.isEmpty) {
        final response = await dio.get('/users');
        setState(() {
          _users =
              (response.data as List)
                  .where((user) => user['role'] == 'controller')
                  .toList();
          _singleUser = null;
        });
      } else if (_isValidId(id)) {
        final response = await dio.get('/users/$id');
        if (response.data['role'] == 'controller') {
          setState(() {
            _singleUser = response.data;
            _users = [];
          });
        } else {
          setState(() {
            _singleUser = null;
            _users = [];
          });
          _showSnackbar('User is not a controller');
        }
      } else {
        _showSnackbar('Please enter a valid numeric ID');
      }
    } catch (e) {
      _showSnackbar('Error fetching user(s)');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteUser() async {
    setState(() => _isLoading = true);
    final id = _idController.text.trim();

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      if (id.isEmpty) {
        final response = await dio.get('/users');
        final users = response.data as List;
        for (var user in users) {
          if (user['role'] == 'controller') {
            await dio.delete('/users/${user['id']}');
          }
        }
        _showSnackbar('All controller users deleted');
      } else if (_isValidId(id)) {
        final response = await dio.get('/users/$id');
        if (response.data['role'] == 'controller') {
          await dio.delete('/users/$id');
          _showSnackbar('Delete successful');
        } else {
          _showSnackbar('Cannot delete non-controller user');
        }
      } else {
        _showSnackbar('Please enter a valid numeric ID');
      }
    } catch (e) {
      _showSnackbar('Delete failed');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateUserDialog() async {
    final id = _idController.text.trim();
    if (!_isValidId(id)) {
      _showSnackbar('Please enter a valid numeric ID');
      return;
    }

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;
      final response = await dio.get('/users/$id');

      if (response.data['role'] != 'controller') {
        _showSnackbar('Only controller users can be modified');
        return;
      }

      Map<String, TextEditingController> controllers = {
        'name': TextEditingController(),
        'surname': TextEditingController(),
        'username': TextEditingController(),
        'email': TextEditingController(),
      };

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Modify user'),
            content: SingleChildScrollView(
              child: Column(
                children:
                    controllers.entries
                        .map(
                          (entry) => TextField(
                            controller: entry.value,
                            decoration: InputDecoration(labelText: entry.key),
                          ),
                        )
                        .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final updatedData = {
                    for (var entry in controllers.entries)
                      entry.key: entry.value.text.trim(),
                  };

                  try {
                    await dio.patch(
                      '/users/$id',
                      data: updatedData,
                      options: Options(
                        headers: {'Content-Type': 'application/json'},
                      ),
                    );
                    _showSnackbar('Update successful');
                    Navigator.of(context).pop();
                  } catch (e) {
                    _showSnackbar('Update failed');
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showSnackbar('Failed to fetch user');
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return ExpansionTile(
      title: Text('User ID: ${user['id']}'),
      children: [
        ListTile(title: Text('Name: ${user['name']}')),
        ListTile(title: Text('Surname: ${user['surname']}')),
        ListTile(title: Text('Username: ${user['username']}')),
        ListTile(title: Text('Email: ${user['email']}')),
        ListTile(title: Text('Role: ${user['role']}')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputId = _idController.text.trim();
    final validId = _isValidId(inputId);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Please enter user ID',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _getUsers,
                  child: const Text('Get Users'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _deleteUser,
                  child: const Text('Delete User(s)'),
                ),
                ElevatedButton(
                  onPressed:
                      (inputId.isNotEmpty && validId && !_isLoading)
                          ? _updateUserDialog
                          : null,
                  child: const Text('Modify User'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                        children: [
                          if (_singleUser != null) _buildUserCard(_singleUser!),
                          ..._users
                              .map<Widget>((user) => _buildUserCard(user))
                              .toList(),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
