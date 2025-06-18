import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../API/client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IssueFinePage extends StatefulWidget {
  const IssueFinePage({super.key});

  @override
  State<IssueFinePage> createState() => _IssueFinePageState();
}

class _IssueFinePageState extends State<IssueFinePage> {
  List<Map<String, dynamic>> assignedZones = [];
  Map<String, dynamic>? selectedZone;
  final List<double> suggestedAmounts = [10, 20, 50];
  double? selectedAmount;
  final TextEditingController _customAmountController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList("zone_ids");
    final names = prefs.getStringList("zone_names");

    if (ids != null && names != null && ids.length == names.length) {
      setState(() {
        assignedZones = List.generate(ids.length, (i) {
          return {
            'id': int.tryParse(ids[i]),
            'name': names[i],
          };
        });
        selectedZone = assignedZones.first;
      });
    }
  }

  Future<void> _submitFine(String plate) async {
    final customText = _customAmountController.text.trim();
    final double? amount = selectedAmount ?? (customText.isNotEmpty ? double.tryParse(customText) : null);

    if (selectedZone == null) {
      setState(() => _errorMessage = "Please select a zone.");
      return;
    }

    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = "Please select or enter a valid amount.");
      return;
    }

    if (plate.trim().length < 3) {
      setState(() => _errorMessage = "Invalid plate format.");
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final dio = DioClient().dio;
    final zid = selectedZone!['id'];

    Future<void> _issueFine() async {
      final response = await dio.post('/zones/$zid/fines', data: {
        "plate": plate,
        "amount": amount,
      });

      if (response.statusCode == 201) {
        final successMsg = "✅ Fine issued for $plate in Zone $zid: €${amount.toStringAsFixed(2)}";
        setState(() {
          _successMessage = successMsg;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        if (context.mounted) Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = "Unexpected response: ${response.statusCode}";
        });
      }
    }

    try {
      await _issueFine();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;

      if (statusCode == 404) {
        try {
          await dio.post('/users/me/cars', data: {
            "plate": plate,
            "brand": "Unknown",
            "model": "Unknown",
          });
          await _issueFine();
          return;
        } catch (e2) {
          setState(() {
            _errorMessage = "Failed to register car or re-issue fine: ${_handleError(e2)}";
          });
        }
      } else {
        setState(() {
          _errorMessage = _handleError(e);
        });
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _handleError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final uri = error.requestOptions.uri;

      if (statusCode == 404) {
        return "❌ 404 Not Found: Endpoint '${uri.path}' does not exist. Check your backend route.";
      }
      if (statusCode == 400) {
        return "❌ 400 Bad Request: Invalid data format.";
      }

      final data = error.response?.data;
      if (data is Map && data.containsKey('detail')) return data['detail'];
      return error.message ?? "Network error";
    }
    return error.toString();
  }

 @override
  Widget build(BuildContext context) {
    final String plate = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: const Text("Issue Fine")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Issuing fine for plate: $plate", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),

            if (assignedZones.isNotEmpty) ...[
              const Text("Select Zone:"),
              const SizedBox(height: 6),
              DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                value: selectedZone,
                items: assignedZones.map((z) {
                  return DropdownMenuItem(
                    value: z,
                    child: Text("Zone ${z['id']} - ${z['name']}"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedZone = value;
                  });
                },
              ),
              const SizedBox(height: 20),
            ],

            const Text("Suggested amounts:"),
            const SizedBox(height: 10),
            Center(
              child: Wrap(
                spacing: 10,
                alignment: WrapAlignment.center,
                children: suggestedAmounts.map((amount) {
                  final isSelected = selectedAmount == amount;
                  return ChoiceChip(
                    label: Text("€${amount.toStringAsFixed(2)}"),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        selectedAmount = amount;
                        _customAmountController.clear();
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Or enter a custom amount (€):"),
            TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "e.g. 35.50",
              ),
              onChanged: (_) {
                setState(() {
                  selectedAmount = null;
                });
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Confirm Fine"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _loading ? null : () => _submitFine(plate),
              ),
            ),
            const SizedBox(height: 10),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            if (_successMessage != null)
              Text(_successMessage!, style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}