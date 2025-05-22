import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login.dart';
import 'manual_check.dart';
import 'ocr/ocr_check.dart';

class ControllerLayout extends StatefulWidget {
  final String username;

  const ControllerLayout({super.key, required this.username});

  @override
  State<ControllerLayout> createState() => _ControllerLayoutState();
}

class _ControllerLayoutState extends State<ControllerLayout> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    "OCR Plate Check",
    "Manual Plate Check",
    "Chalked Cars",
    "Fines Issued",
  ];

  final List<Widget> _pages = [
    const OCRCheck(),
    const ManualCheckPage(),
    const PlaceholderWidget(title: "Chalked Cars Page"),
    const PlaceholderWidget(title: "Fines Issued Page"),
  ];

  void _onItemTapped(int index) {
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: "OCR"),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: "Manual"),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: "Chalked"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Fines"),
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