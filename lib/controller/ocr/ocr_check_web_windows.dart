import 'package:flutter/material.dart';

class OCRCheck extends StatelessWidget {
  const OCRCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: "AB123CD");

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text("Simulated OCR (Web/Desktop)", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Detected Plate",
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final plate = controller.text.trim().toUpperCase();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Checking plate: $plate")),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
