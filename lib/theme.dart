import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F1118);
  static const surface = Color(0xFF181B26);
  static const surfaceHigh = Color(0xFF222636);
  static const gold = Color(0xFFF2B544);
  static const specialBlue = Color(0xFF3FA9F5);
  static const emptyStar = Color(0xFF4A4F63);
  static const text = Color(0xFFEDE7DA);
  static const textDim = Color(0xFF9A9CAB);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.gold,
    onPrimary: const Color(0xFF241A05),
    surface: AppColors.surface,
    onSurface: AppColors.text,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
