import 'package:flutter/material.dart';
import 'ocr_check_page.dart';
// Qui in futuro importeremo anche le altre:
// import 'manual_check_page.dart';
// import 'chalked_cars_page.dart';
// import 'fines_page.dart';
// import 'profile_page.dart';

class ControllerHomePage extends StatefulWidget {
  const ControllerHomePage({super.key});

  @override
  State<ControllerHomePage> createState() => _ControllerHomePageState();
}

class _ControllerHomePageState extends State<ControllerHomePage> {
  int _selectedIndex = 0;

  // Lista di pagine (per ora solo OCR è implementata realmente)
  final List<Widget> _pages = [
    const OCRCheckPage(),
    const PlaceholderWidget(title: 'Manual Check Page'),
    const PlaceholderWidget(title: 'Chalked Cars Page'),
    const PlaceholderWidget(title: 'Fines Issued Page'),
    const PlaceholderWidget(title: 'Profile Page'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'OCR Check'),
    BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Manual Check'),
    BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Chalked'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Fines'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Placeholder temporanei
class PlaceholderWidget extends StatelessWidget {
  final String title;
  const PlaceholderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title, style: const TextStyle(fontSize: 20)));
  }
}
