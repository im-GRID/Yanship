// lib/providers/language_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  
  Locale get currentLocale => _currentLocale;

  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('fr', ''), // French
    Locale('ar', ''), // Arabic
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'fr': 'Français',
    'ar': 'العربية',
  };

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> changeLanguage(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }

  bool get isRTL => _currentLocale.languageCode == 'ar';
  
  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }
}