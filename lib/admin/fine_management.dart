import 'package:flutter/material.dart';
import 'package:openpark/admin/utils/url_dao.dart';

import '../singleton/dio_client.dart';

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

  bool _isValidId(String input) {
    return int.tryParse(input) != null;
  }

  Future<void> _getFines() async {
    setState(() => _isLoading = true);
    final id = _idController.text.trim();

    try {
      await DioClient().setAuthToken();
      final dio = DioClient().dio;

      if (id.isEmpty) {
        final response = await dio.get(fineUrl);
        setState(() {
          _fines = response.data;
          _singleFine = null;
        });
      } else if (_isValidId(id)) {
        final response = await dio.get('$fineUrl/$id');
        setState(() {
          _singleFine = response.data;
          _fines = [];
        });
      } else {
        _showSnackbar('Please enter a valid numeric ID');
      }
    } catch (e) {
      _showSnackbar('Error fetching fine(s)');
    }

    setState(() => _isLoading = false);
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Please enter fine ID',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _getFines,
              child: const Text('Get Fines'),
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
