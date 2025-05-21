import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class OCRCheck extends StatefulWidget {
  const OCRCheck({super.key});

  @override
  State<OCRCheck> createState() => _OCRCheckState();
}

class _OCRCheckState extends State<OCRCheck> {
  File? _image;
  String? _scannedPlate;
  final TextEditingController _controller = TextEditingController();

  Future<void> _pickImage() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _image = imageFile;
        });
        _performOCR(imageFile);
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings(); // opzionale: apre le impostazioni app se negato in modo permanente
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permesso fotocamera negato. Modifica dalle impostazioni.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permesso fotocamera non concesso")),
      );
    }
  }

  Future<void> _performOCR(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    textRecognizer.close();

    final allText = recognizedText.text;

    // Estrai prima parola maiuscola tipo targa italiana
    final regex = RegExp(r'\b[A-Z]{2}\d{3}[A-Z]{2}\b');
    final match = regex.firstMatch(allText);

    if (match != null) {
      final plate = match.group(0);
      setState(() {
        _scannedPlate = plate;
        _controller.text = plate!;
      });
    } else {
      setState(() {
        _scannedPlate = null;
        _controller.text = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Targa non riconosciuta")),
      );
    }
  }

  void _submitPlate() {
    final plate = _controller.text.trim().toUpperCase();
    if (plate.isEmpty) return;

    // Qui potrai collegare l’API per la verifica della targa
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Verifica in corso per: $plate')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Scatta foto"),
            ),
            const SizedBox(height: 20),
            if (_image != null)
              Image.file(_image!, height: 180),
            if (_scannedPlate != null || _controller.text.isNotEmpty) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
                decoration: const InputDecoration(
                  labelText: "Targa rilevata",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _submitPlate,
                child: const Text("Verifica"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
