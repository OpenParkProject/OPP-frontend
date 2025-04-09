import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:opp_frontend/myDrawer.dart';
import 'package:opp_frontend/parking_info.dart';

class PlateScannerScreen extends StatefulWidget {
  const PlateScannerScreen({super.key});

  @override
  _PlateScannerScreenState createState() => _PlateScannerScreenState();
}

class _PlateScannerScreenState extends State<PlateScannerScreen> {
  CameraController? _controller;
  bool isCameraInitialized = false;
  List<CameraDescription>? cameras;
  String recognizedText = "";
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras!.first, ResolutionPreset.medium);
    await _controller!.initialize();
    setState(() => isCameraInitialized = true);
  }

  Future<void> _takePictureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final image = await _controller!.takePicture();
    await _performOCR(image);
  }

  Future<void> _performOCR(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedTextResult = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    setState(() {
      recognizedText = recognizedTextResult.text;
      textController.text = recognizedTextResult.text; // 自动填充到输入框
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(title: const Text("OCR")),
      body: Column(
        children: [
          isCameraInitialized
              ? Expanded(child: CameraPreview(_controller!))
              : const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 10),
          Text("Result: $recognizedText", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Plate number",
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _takePictureAndRecognize,
            child: const Text("Scan and recognise plate"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ParkingPaymentPage()),
              );
            },
            child: const Text("Confirm your plate"),
          ),
        ],
      ),
    );
  }
}
