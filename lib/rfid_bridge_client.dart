import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'config.dart';
import 'dart:async';

Future<(bool, String)> RFID_read() async {
  if (isTotem){
    bool res = false;
    String retResponse = '';

    final channel = WebSocketChannel.connect(
      Uri.parse(readerWsUrl),
    );

    Completer<(bool, String)> completer = Completer();
    
    // 5-second timeout
    Timer timer = Timer(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        debugPrint('RFID read timeout after 5 seconds');
        channel.sink.close();
        completer.complete((false, 'Connection timeout after 5 seconds'));
      }
    });

    // Send a read command
    channel.sink.add('read');
    
    // Wait for a response
    channel.stream.listen(
      (response) {
        timer.cancel();
        res = true;
        retResponse = response.toString();
        channel.sink.close();
        if (!completer.isCompleted) {
          completer.complete((res, retResponse));
        }
      },
      onError: (error) {
        timer.cancel();
        res = false;
        retResponse = error.toString();
        channel.sink.close();
        if (!completer.isCompleted) {
          completer.complete((res, retResponse));
        }
      },
      onDone: () {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete((res, retResponse));
        }
      },
    );
    
    return completer.future;
  } else {
    debugPrint('RFID not supported in this device.');
    return Future.value((false, 'RFID not supported in this device.'));
  }
}