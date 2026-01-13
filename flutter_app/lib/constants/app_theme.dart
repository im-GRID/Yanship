import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE53E3E);
  static const Color secondary = Colors.orange;
  static const Color surface = Colors.white;
  static const Color background = Colors.white;
// Ajoutez d'autres couleurs si nécessaire
}

ThemeData appLightTheme() {
  return ThemeData(
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      background: AppColors.background,
    ),
  );
}