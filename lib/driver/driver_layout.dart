import 'package:flutter/material.dart';
import 'tickets.dart';
import 'profile.dart';
import 'my_cars.dart';
import 'my_fines.dart';

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
      UserTicketsPage(),
      MyCarsPage(),
      MyFinesPage(),
      ProfilePage(),
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
          NavigationDestination(icon: Icon(Icons.confirmation_num), label: 'My Tickets'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'My Cars'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'My Fines'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
