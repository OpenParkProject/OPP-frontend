import 'package:flutter/material.dart';
import 'debug_online.dart';
import 'debug_offline.dart';

class DebugModeSelector extends StatelessWidget {
  const DebugModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Debug Mode')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choose debug mode:", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DebugRoleSelectorOnline()),
                  );
                },
                icon: const Icon(Icons.cloud),
                label: const Text('Debug – Online Mode'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DebugRoleSelectorOffline()),
                  );
                },
                icon: const Icon(Icons.offline_bolt),
                label: const Text('Debug – Offline Mode'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
