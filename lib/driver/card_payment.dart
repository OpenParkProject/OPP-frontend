import 'package:flutter/material.dart';
import 'package:openpark/config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class CardPaymentPage extends StatefulWidget {
  final Future<void> Function() onConfirmed;

  const CardPaymentPage({super.key, required this.onConfirmed});

  @override
  State<CardPaymentPage> createState() => _CardPaymentPageState();
}

class _CardPaymentPageState extends State<CardPaymentPage> {
  String status = "Please tap your card on the reader...";
  bool done = false;

  @override
  void initState() {
    super.initState();
    _startRFIDRead();
  }

  void _startRFIDRead() async {
    final channel = WebSocketChannel.connect(Uri.parse(readerWsUrl));
    channel.sink.add("read");

    channel.stream.listen((message) async {
      if (done) return;
      done = true;

      setState(() => status = "Card detected: $message\nAuthorizing...");

      await Future.delayed(const Duration(seconds: 2));
      setState(() => status = "✅ Transaction approved!");

      await Future.delayed(const Duration(seconds: 1));
      channel.sink.close();
      await widget.onConfirmed();
    }, onError: (err) {
      setState(() => status = "❌ Error reading RFID");
      channel.sink.close();
    }, onDone: () {
      if (!done) {
        setState(() => status = "⚠️ RFID read ended without success.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pay by Card")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.credit_card, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text(status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
