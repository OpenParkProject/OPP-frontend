import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool hasScanned = false;
  late final MobileScannerController scannerController;

  @override
  void initState() {
    super.initState();
    scannerController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      torchEnabled: false,
    );
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue;

    if (code != null && code.isNotEmpty) {
      hasScanned = true;
      try {
        final parsed = jsonDecode(code);
        if (parsed is Map &&
            parsed.containsKey('id') &&
            parsed.containsKey('timestamp')) {
          Navigator.pop(context, parsed);
        } else {
          _showInvalidFormat();
        }
      } catch (_) {
        _showInvalidFormat();
      }
    }
  }

  void _showInvalidFormat() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Invalid QR Code format")));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Totem QR")),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: scannerController,
              onDetect: _handleBarcode,
              fit: BoxFit.cover,
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(child: Text("Scan the QR code shown on the Totem")),
          ),
        ],
      ),
    );
  }
}
