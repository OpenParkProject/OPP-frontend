// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:opp_frontend/parking_info.dart';
import 'package:opp_frontend/settings.dart';
import 'main.dart';
import 'theme_notifier.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MyDrawer extends StatelessWidget {

  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text("name"),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage("images/Car.jpg"),
            ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage("images/ParkingBG.png"),
              ),
            ), accountEmail: null,
          ),
          ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.car_crash, color: Theme.of(context).iconTheme.color),
            ),
            title: Text("Car's data",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ParkingPaymentPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.settings,
                  color: Theme.of(context).iconTheme.color),
            ),
            title: Text("Settings",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserProfilePage()),
              );
            },
          ),
          ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.logout,
                  color: Theme.of(context).iconTheme.color),
            ),
            title: Text("Log out",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
          ListTile(
            leading: CircleAvatar(
              child: Icon(Provider.of<ThemeNotifier>(context).currentThemeIcon,
                  color: Theme.of(context).iconTheme.color),
            ),
            title: Text("Change Theme",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            onTap: () {
              Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
    );
  }
}
