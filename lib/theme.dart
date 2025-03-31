// lib/theme.dart
import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.green,
    secondaryHeaderColor: Colors.greenAccent,
    scaffoldBackgroundColor: Colors.green[100],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 10.0,
      /*titleTextStyle: GoogleFonts.roboto(
        color: Colors.white,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),*/
    ),
    cardColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.green),
    /*textTheme: TextTheme(
      bodySmall: GoogleFonts.roboto(color: Colors.black),
      bodyMedium: GoogleFonts.roboto(color: Colors.black),
      headlineSmall: GoogleFonts.roboto(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18.0),
    ),*/
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.grey,
    secondaryHeaderColor: Colors.teal,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey,
      foregroundColor: Colors.white,
      elevation: 10.0,
      /*titleTextStyle: GoogleFonts.roboto(
        color: Colors.white,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),*/
    ),
    cardColor: Colors.grey[800],
    iconTheme: const IconThemeData(color: Colors.teal),
    /*textTheme: TextTheme(
      bodySmall: GoogleFonts.roboto(color: Colors.white),
      bodyMedium: GoogleFonts.roboto(color: Colors.white),
      headlineSmall: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.0),
    ),*/
  );
}
