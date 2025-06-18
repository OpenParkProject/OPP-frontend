import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login.dart';

class GlobalInactivityHandler extends StatefulWidget {
  final Widget child;

  const GlobalInactivityHandler({super.key, required this.child});

  @override
  State<GlobalInactivityHandler> createState() => _GlobalInactivityHandlerState();
}

class _GlobalInactivityHandlerState extends State<GlobalInactivityHandler> {
  Timer? _inactivityTimer;
  bool _isTotem = false;

  @override
  void initState() {
    super.initState();
    _loadTotemStatus();
  }

  Future<void> _loadTotemStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isTotem = prefs.getBool('isTotem') == true;
    });
    _resetTimer();
  }

  void _resetTimer() {
    if (!_isTotem) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 3), _logout);
  }

  void _logout() {
    if (!_isTotem) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerSignal: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
