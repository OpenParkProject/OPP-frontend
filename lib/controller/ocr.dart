import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/widgets/ticket_check_widget.dart';

class OCRPage extends StatefulWidget {
  final String username;
  const OCRPage({super.key, required this.username});

  @override
  State<OCRPage> createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  bool _processing = false;
  String? _confirmedPlate;

  final List<Map<String, dynamic>> _history = []; // { "imagePath": String, "text": String }
  final ImagePicker _picker = ImagePicker();

  bool get isOCREnabled => Platform.isAndroid || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? plates = prefs.getStringList('ocr_plates');
    final List<String>? paths = prefs.getStringList('ocr_paths');

    if (plates != null && paths != null && plates.length == paths.length) {
      setState(() {
        _history.clear();
        for (int i = 0; i < plates.length; i++) {
          _history.add({"imagePath": paths[i], "text": plates[i]});
        }
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final plates = _history.map((e) => e['text'] as String).toList();
    final paths = _history.map((e) => e['imagePath'] as String).toList();
    await prefs.setStringList('ocr_plates', plates);
    await prefs.setStringList('ocr_paths', paths);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!isOCREnabled) {
      _showError("OCR is not supported on this device.");
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);
      setState(() => _processing = true);

      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final fullText = recognizedText.text;
      final plateReg = RegExp(r'[A-Z]{2}[0-9]{3}[A-Z]{2}');
      final match = plateReg.firstMatch(fullText.replaceAll(RegExp(r'\s+'), '').toUpperCase());
      final extractedPlate = match?.group(0);

    if (!mounted) return;

    if (extractedPlate != null) {
      _showPlateConfirmationDialog(imageFile, extractedPlate, fullText);
    } else {
      _showRetryOrEditDialog(imageFile, fullText);
    }

    } catch (e) {
      _showError('Error: $e');
      setState(() => _processing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showRetryOrEditDialog(File image, String fullText) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Plate not recognized"),
          content: const Text(
            "No license plate detected in the image."
            "Do you want to try again or manually edit the recognized text?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: const Text("Retry"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showFullTextEditDialog(image, fullText);
              },
              child: const Text("Edit detected  text"),
            ),
          ],
        );
      },
    ).then((_) => setState(() => _processing = false));
  }

  void _showPlateConfirmationDialog(File image, String plate, String fullText) {
    final TextEditingController plateController = TextEditingController(text: plate);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Plate Found"),
        content: TextField(
          controller: plateController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Detected Plate",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showFullTextEditDialog(image, fullText);
            },
            child: const Text("Edit Full Text"),
          ),
          ElevatedButton(
            onPressed: () async {
              final confirmed = plateController.text.trim().toUpperCase();
              final valid = RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$').hasMatch(confirmed);
              if (valid) {
                final savedImage = await _saveImageToLocalDir(image);
                _addToHistory(savedImage, confirmed);
                Navigator.pop(context);
              } else {
                _showError("Plate must be in format AB123CD");
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    ).then((_) => setState(() => _processing = false));
  }

  void _showFullTextEditDialog(File image, String initialText) {
    final TextEditingController controller = TextEditingController(text: initialText);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit OCR Full Text"),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.toUpperCase();
              final match = RegExp(r'[A-Z]{2}[0-9]{3}[A-Z]{2}').firstMatch(text.replaceAll(RegExp(r'\s+'), ''));
              final plate = match?.group(0);
              if (plate != null) {
                final savedImage = await _saveImageToLocalDir(image);
                _addToHistory(savedImage, plate);
                Navigator.pop(context);
              } else {
                _showError("No valid plate found.");
              }
            },
            child: const Text("Confirm Plate"),
          ),
        ],
      ),
    );
  }

  Future<File> _saveImageToLocalDir(File image) async {
    final dir = await getApplicationDocumentsDirectory();
    final newPath = '${dir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return image.copy(newPath);
  }

  void _addToHistory(File image, String plate) async {
    setState(() {
      _confirmedPlate = plate;
      _history.insert(0, {
        "imagePath": image.path,
        "text": plate,
      });
      if (_history.length > 4) _history.removeLast();
    });
    await _saveHistory();
  }

  Widget _buildHistory() {
    if (_history.isEmpty) return const Text("No OCR history yet.");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recent OCRs:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _history.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = _history[index];
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(entry['imagePath']),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(entry['text'], style: const TextStyle(fontSize: 12)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isOCREnabled) {
      return Scaffold(
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'OCR is not available on this device.\n\nSupported only on Android and Linux desktop.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('OCR Scanner')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take a picture'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose from gallery'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_processing) const CircularProgressIndicator(),
              const SizedBox(height: 20),
              _buildHistory(),
              const SizedBox(height: 20),
              if (_confirmedPlate != null)
                TicketCheckWidget(
                  plate: _confirmedPlate!,
                  username: widget.username,
                ),
            ],
          ),
        ),
      ),
    );
  }
}