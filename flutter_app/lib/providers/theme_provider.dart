import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  bool get isDark => _themeMode == ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_mode');
    
    if (themeString == null) {
      _themeMode = ThemeMode.system;
    } else if (themeString == 'ThemeMode.dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeString == 'ThemeMode.light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    
    // Store theme preference to handle all three modes
    if (mode == ThemeMode.system) {
      await prefs.remove('theme_mode'); // Use system default
    } else {
      await prefs.setString('theme_mode', mode.toString());
    }
    
    notifyListeners();
  }

  // Keep the old toggleTheme method for backward compatibility
  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}