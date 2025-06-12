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
    setState(() => _submitting = true);

    await Future.delayed(const Duration(seconds: 2)); // simulate processing

    setState(() => _submitting = false);
    await widget.onConfirmed();
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
              ),
              TextFormField(
                controller: _cardNumber,
                decoration: const InputDecoration(labelText: 'Card Number'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _expiryDate,
                decoration: const InputDecoration(labelText: 'Expiry Date (MM/YY)'),
                keyboardType: TextInputType.datetime,
              ),
              TextFormField(
                controller: _cvv,
                decoration: const InputDecoration(labelText: 'CVV'),
                obscureText: true,
                keyboardType: TextInputType.number,
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
