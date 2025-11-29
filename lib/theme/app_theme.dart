import 'package:flutter/material.dart';

class AppTheme {
  // 提取自截图的深色系
  static const Color primaryColor = Color(0xFF6C63FF); // 更加柔和的紫色/蓝色
  static const Color secondaryColor = Color(0xFF2A2D3E);
  static const Color backgroundColor = Color(0xFF1F1D2B); // 深蓝灰背景
  static const Color surfaceColor = Color(0xFF252836);
  static const Color inputFillColor = Color(0xFF2F3142);
  static const Color textColor = Colors.white;
  static const Color textSecondaryColor = Color(0xFF808191);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondaryColor, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textSecondaryColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Light grey background
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: Colors.white,
        surface: Colors.white,
        background: Color(0xFFF5F5F7),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        hintStyle: const TextStyle(color: Colors.black38),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      useMaterial3: true,
    );
  }
}
