import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login.dart';
import 'admin_management.dart';
import 'controller_management.dart';
import 'driver_management.dart';
import 'statistics.dart';

class SuperuserLayout extends StatefulWidget {
  final String username;
  const SuperuserLayout({super.key, required this.username});

  @override
  State<SuperuserLayout> createState() => _SuperuserLayoutState();
}

class _SuperuserLayoutState extends State<SuperuserLayout> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;
  late final List<String> _titles;

  @override
  void initState() {
    super.initState();
    _pages = [
      SuperuserAdminManagementPage(username: widget.username),
      SuperuserControllerManagementPage(username: widget.username),
      SuperuserDriverManagementPage(username: widget.username),
      const SuperuserStatisticsPage(),
    ];

    _titles = [
      "Admin Users",
      "Controller Users",
      "Driver Users",
      "System Statistics",
    ];
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final keepKeys = {
      'isTotem',
      'zone_id',
      'zone_name',
      'latitude',
      'longitude',
      'rfid_enabled'
    };

    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (!keepKeys.contains(key)) {
        await prefs.remove(key);
      }
    }

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
    final List<Icon> _icons = [
      const Icon(Icons.security),
      const Icon(Icons.supervisor_account),
      const Icon(Icons.person),
      const Icon(Icons.bar_chart),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
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
                label: !isCompact || index == _selectedIndex
                    ? _titles[index]
                    : '',
              );
            }),
          );
        },
      ),
    );
  }
}
