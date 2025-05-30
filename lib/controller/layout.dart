//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';

import '../login.dart';
import 'chalked_cars.dart';
import 'fines_issued.dart';
import 'manual_check.dart';
import 'ocr.dart';

//bool get isOcrSupported => Platform.isAndroid || Platform.isLinux;
bool get isOcrSupported =>
    UniversalPlatform.isAndroid || UniversalPlatform.isLinux;

class ControllerLayout extends StatefulWidget {
  final String username;

  const ControllerLayout({super.key, required this.username});

  @override
  State<ControllerLayout> createState() => _ControllerLayoutState();
}

class _ControllerLayoutState extends State<ControllerLayout> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex =
        isOcrSupported
            ? 0
            : 1; // lands on  "Manual" if OCR is not supported on the device
  }

  final List<String> _titles = [
    "OCR Plate Check",
    "Manual Plate Check",
    "Chalked Cars",
    "Fines Issued",
  ];

  List<Widget> get _pages => [
    if (isOcrSupported)
      OCRPage(username: widget.username)
    else
      const PlaceholderWidget(title: 'OCR not supported on this device.'),
    ManualCheckPage(username: widget.username),
    ChalkedCarsPage(username: widget.username),
    const FinesIssuedPage(),
  ];

  void _onItemTapped(int index) {
    if (index == 0 && !isOcrSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OCR is not supported on this device.'),
          duration: Duration(seconds: 3),
        ),
      );
      return; // blocks page change
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 360) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '👮 Controller Interface',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _titles[_selectedIndex],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            } else {
              return Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '👮 Controller Interface',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    _titles[_selectedIndex],
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              );
            }
          },
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Text(
                widget.username,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.camera_alt,
              color:
                  isOcrSupported
                      ? null
                      : Colors.grey, // disattivato visivamente
            ),
            label: "OCR",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: "Manual",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: "Chalked",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: "Fines",
          ),
        ],
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String title;
  const PlaceholderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title, style: const TextStyle(fontSize: 20)));
  }
}
