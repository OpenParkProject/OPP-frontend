import 'package:flutter/material.dart';

class OCRCheckPage extends StatefulWidget {
  const OCRCheckPage({super.key});

  @override
  State<OCRCheckPage> createState() => _OCRCheckPageState();
}

class _OCRCheckPageState extends State<OCRCheckPage> {
  String? scannedPlate;
  final TextEditingController _plateController = TextEditingController();

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  void _simulateScan() {
    // Simulazione della lettura OCR
    setState(() {
      scannedPlate = "AB123CD";
      _plateController.text = scannedPlate!;
    });
  }

  void _submitPlate() {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isNotEmpty) {
      // Qui aggiungerai la chiamata al backend o la verifica
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verifica in corso per: $plate')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Plate Check')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _simulateScan,
              child: const Text("Scan Plate via Camera"),
            ),
            const SizedBox(height: 24),
            if (scannedPlate != null) ...[
              Text("Targa rilevata:", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _plateController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Inserisci o modifica la targa',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitPlate,
                child: const Text("Submit"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
