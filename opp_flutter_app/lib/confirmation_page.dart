import 'package:flutter/material.dart';

class ConfirmationPage extends StatelessWidget {
  final String plateNumber; // La targa inserita, passata dalla schermata precedente

  // Costruttore che riceve la targa
  ConfirmationPage({required this.plateNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You inserted the plate: $plateNumber',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Torna alla schermata precedente
                Navigator.pop(context);
              },
              child: const Text('Insert another plate'),
            ),
          ],
        ),
      ),
    );
  }
}
