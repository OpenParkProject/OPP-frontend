import 'package:flutter/material.dart';

class OCRCheck extends StatelessWidget {
  const OCRCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("OCR not supported on this platform."),
      ),
    );
  }
}
