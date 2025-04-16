import 'package:flutter/material.dart';
import 'user_home.dart';
import 'register_plate.dart';
import 'profile.dart';

class MainUserHomePage extends StatefulWidget {
  final String username;

  const MainUserHomePage({super.key, required this.username});

  @override
  State<MainUserHomePage> createState() => _MainUserHomePageState();
}

class _MainUserHomePageState extends State<MainUserHomePage> {
  int _selectedIndex = 0;

  static late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      UserHomePage(userEmail: widget.username),
      RegisterPlatePage(userEmail: widget.username),
      ProfilePage(username: widget.username),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'My Cars'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
