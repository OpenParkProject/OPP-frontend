import 'package:flutter/material.dart';

class ManualCardFormPage extends StatefulWidget {
  final Future<void> Function() onConfirmed;

  const ManualCardFormPage({super.key, required this.onConfirmed});

  @override
  State<ManualCardFormPage> createState() => _ManualCardFormPageState();
}

class _ManualCardFormPageState extends State<ManualCardFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameSurname = TextEditingController();
  final _cardNumber = TextEditingController();
  final _expiryDate = TextEditingController();
  final _cvv = TextEditingController();

  bool _submitting = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    await Future.delayed(const Duration(seconds: 2)); // simulate processing

    setState(() => _submitting = false);
    await widget.onConfirmed();
  }

  bool _isExpiryValid(String input) {
    try {
      final parts = input.split('/');
      if (parts.length != 2) return false;

      final month = int.tryParse(parts[0]);
      final year = int.tryParse(parts[1]);

      if (month == null || year == null || month < 1 || month > 12) return false;

      final now = DateTime.now();
      final inputDate = DateTime(2000 + year, month + 1); // assume 20YY

      return inputDate.isAfter(now);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Card Details")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameSurname,
                decoration: const InputDecoration(labelText: 'Name and Surname'),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return "Enter a valid name and surname.";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cardNumber,
                decoration: const InputDecoration(labelText: 'Card Number'),
                keyboardType: TextInputType.number,
                maxLength: 16,
                validator: (value) {
                  if (value == null || value.length != 16 || !RegExp(r'^\d{16}$').hasMatch(value)) {
                    return "Enter a valid 16-digit card number.";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _expiryDate,
                decoration: const InputDecoration(labelText: 'Expiry Date (MM/YY)'),
                keyboardType: TextInputType.datetime,
                maxLength: 5,
                validator: (value) {
                  if (value == null || !_isExpiryValid(value)) {
                    return "Enter a valid future date (MM/YY).";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cvv,
                decoration: const InputDecoration(labelText: 'CVV'),
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 3,
                validator: (value) {
                  if (value == null || !RegExp(r'^\d{3}$').hasMatch(value)) {
                    return "Enter a valid 3-digit CVV.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text("Confirm Payment"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
