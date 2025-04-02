// lib/theme_notifier.dart
import 'package:flutter/material.dart';
import 'theme.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeData _currentTheme = AppThemes.lightTheme;
  bool _isDarkMode = false;

  ThemeData get currentTheme => _currentTheme;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    if (_isDarkMode) {
      _currentTheme = AppThemes.lightTheme;
    } else {
      _currentTheme = AppThemes.darkTheme;
    }
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  IconData get currentThemeIcon => _isDarkMode ? Icons.brightness_7 : Icons.brightness_2;
}
