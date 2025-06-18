import 'package:flutter/material.dart';
import 'package:openpark/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';
import '../login.dart';
import 'fines_issued.dart';
import 'manual_check.dart';
import 'ocr.dart';
import 'assigned_zones.dart';

bool get isOcrSupported =>
    UniversalPlatform.isAndroid || UniversalPlatform.isLinux;

class ControllerLayout extends StatefulWidget {
  final String username;
  final String? successMessage;

  const ControllerLayout({super.key, required this.username, this.successMessage});

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

    if (widget.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.successMessage!)),
        );
      });
    }
  }

  final List<String> _titles = [
    "OCR Plate Check",
    "Manual Plate Check",
    //"Chalked Cars",
    "Fines Issued",
    "Assigned Zones",
  ];

  List<Widget> get _pages => [
    if (isOcrSupported)
      OCRPage(username: widget.username)
    else
      const PlaceholderWidget(title: 'OCR not supported on this device.'),
    ManualCheckPage(username: widget.username),
    //ChalkedCarsPage(username: widget.username),
    const FinesIssuedPage(),
    AssignedZonesPage(username: widget.username),
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
        backgroundColor: Colors.blue,
        toolbarHeight: 60,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final interfaceTitle =
                globalRole == 'admin'
                    ? '👨🏻‍💻 Admin Interface'
                    : '👮 Controller Interface';
            if (constraints.maxWidth < 360) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // '👮 Controller Interface',
                      interfaceTitle,
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      // '👮 Controller Interface',
                      interfaceTitle,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                      : Colors.grey,
            ),
            label: "OCR",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: "Manual",
          ),
          // const BottomNavigationBarItem(
          //   icon: Icon(Icons.directions_car),
          //   label: "Chalked",
          // ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: "Fines",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "My Zones",
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
