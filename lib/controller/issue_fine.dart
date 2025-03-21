import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../singleton/dio_client.dart';

class IssueFinePage extends StatefulWidget {
  const IssueFinePage({super.key});

  @override
  State<IssueFinePage> createState() => _IssueFinePageState();
}

class _IssueFinePageState extends State<IssueFinePage> {
  final List<double> suggestedAmounts = [10, 20, 50];
  double? selectedAmount;
  final TextEditingController _customAmountController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _submitFine(String plate) async {
    final customText = _customAmountController.text.trim();
    final double? amount = selectedAmount ?? (customText.isNotEmpty ? double.tryParse(customText) : null);

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

    try {
      final dio = DioClient().dio;

      // Verifica se il backend richiede /fines/{plate} oppure solo /fines con plate nel body
      final response = await dio.post('/fines/$plate', data: {
        "plate": plate,
        "amount": amount,
      });

      if (response.statusCode == 201) {
        final successMsg = "✅ Fine issued for $plate: €${amount.toStringAsFixed(2)}";
        setState(() {
          _successMessage = successMsg;
        });

        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // After 2 seconds, go back to controller homepage
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) Navigator.pop(context);

      } else {
        setState(() {
          _errorMessage = "Unexpected response: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${_handleError(e)}";
      });
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