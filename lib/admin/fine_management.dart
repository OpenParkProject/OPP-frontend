// fine_management_page.dart
import 'package:flutter/material.dart';

import '../API/client.dart';

class FineManagementPage extends StatefulWidget {
  const FineManagementPage({super.key});

  @override
  State<FineManagementPage> createState() => _FineManagementPageState();
}

class _FineManagementPageState extends State<FineManagementPage> {
  final TextEditingController _idController = TextEditingController();
  List<dynamic> _fines = [];
  Map<String, dynamic>? _singleFine;
  bool _isLoading = false;

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidId(String input) => int.tryParse(input) != null;

  Future<void> _getFines() async {
    setState(() => _isLoading = true);
    final id = _idController.text.trim();
    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      if (id.isEmpty) {
        final res = await dio.get('fines');
        setState(() {
          _fines = res.data;
          _singleFine = null;
        });
      } else if (_isValidId(id)) {
        final res = await dio.get('fines/$id');
        setState(() {
          _singleFine = res.data;
          _fines = [];
        });
      } else {
        _showSnackbar('Invalid ID');
      }
    } catch (_) {
      _showSnackbar('Error fetching fine(s)');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteFine() async {
    final id = _idController.text.trim();
    if (!_isValidId(id)) {
      _showSnackbar('Invalid ID');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await DioClient().setAuthToken();
      final res = await DioClient().dio.delete('fines/$id');
      if (res.statusCode == 200) {
        _showSnackbar('Fine deleted');
        _getFines();
      } else {
        _showSnackbar('Failed to delete');
      }
    } catch (_) {
      _showSnackbar('Error deleting fine');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _editFine() async {
    final id = _idController.text.trim();
    if (!_isValidId(id)) {
      _showSnackbar('Invalid ID');
      return;
    }

    Map<String, TextEditingController> fields = {
      'plate': TextEditingController(),
      'amount': TextEditingController(),
      'paid': TextEditingController(),
    };

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Fine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                fields.entries.map((entry) {
                  return TextField(
                    controller: entry.value,
                    decoration: InputDecoration(labelText: entry.key),
                  );
                }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await DioClient().setAuthToken();
                  final updatedData = {
                    'plate': fields['plate']!.text.trim(),
                    'amount':
                        double.tryParse(fields['amount']!.text.trim()) ?? 0.0,
                    'paid': fields['paid']!.text.trim().toLowerCase() == 'true',
                  };

                  final res = await DioClient().dio.patch(
                    'fines/$id',
                    data: updatedData,
                  );
                  if (res.statusCode == 200) {
                    _showSnackbar('Updated');
                    Navigator.pop(context);
                    _getFines();
                  } else {
                    _showSnackbar('Update failed');
                  }
                } catch (_) {
                  _showSnackbar('Error updating fine');
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFineCard(Map<String, dynamic> fine) {
    return ExpansionTile(
      title: Text('Fine ID: ${fine['id']}'),
      children: [
        ListTile(title: Text('Plate: ${fine['plate']}')),
        ListTile(title: Text('Date: ${fine['date']}')),
        ListTile(title: Text('Amount: ${fine['amount']}')),
        ListTile(title: Text('Paid: ${fine['paid']}')),
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
              decoration: const InputDecoration(labelText: 'Enter Fine ID'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _getFines,
                  child: const Text('Get'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: validId ? _deleteFine : null,
                  child: const Text('Delete'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: validId ? _editFine : null,
                  child: const Text('Edit'),
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
                          if (_singleFine != null) _buildFineCard(_singleFine!),
                          ..._fines
                              .map<Widget>(
                                (fine) => _buildFineCard(
                                  Map<String, dynamic>.from(fine),
                                ),
                              )
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
