import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login.dart';

class AdminLayout extends StatefulWidget {
  final String username;

  const AdminLayout({super.key, required this.username});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    "Controllers",
    "Fines",
    "Totems",
    "Tickets",
    "Check Plate",
    "Zones"
  ];

  final List<Widget> _pages = [
    PlaceholderWidget(title: "Controllers management"),
    PlaceholderWidget(title: "City fines"),
    PlaceholderWidget(title: "Totem locations"),
    PlaceholderWidget(title: "City tickets"),
    PlaceholderWidget(title: "Plate check (as controller)"),
    PlaceholderWidget(title: "Zone pricing and status")
  ];

  final List<Icon> _icons = [
    Icon(Icons.shield),
    Icon(Icons.receipt_long),
    Icon(Icons.place),
    Icon(Icons.confirmation_num),
    Icon(Icons.search),
    Icon(Icons.map_outlined),
  ];

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
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
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 460;

          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: !isCompact,
            items: List.generate(_titles.length, (index) {
              return BottomNavigationBarItem(
                icon: _icons[index],
                label: !isCompact || index == _selectedIndex ? _titles[index] : '',
              );
            }),
          );
        },
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