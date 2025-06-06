import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool hasScanned = false;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    ctrl.scannedDataStream.listen((scanData) {
      if (!hasScanned) {
        hasScanned = true;
        try {
          final parsed = jsonDecode(scanData.code ?? '');
          if (parsed is Map && parsed.containsKey('id') && parsed.containsKey('timestamp')) {
            Navigator.pop(context, parsed);
          } else {
            _showInvalidFormat();
          }
        } catch (_) {
          _showInvalidFormat();
        }
      }
    });
  }

  void _showInvalidFormat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Invalid QR Code format")),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan Totem QR")),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blueAccent,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text("Scan the QR code shown on the Totem"),
            ),
          )
        ],
      ),
    );
  }
}
