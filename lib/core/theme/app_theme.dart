import 'package:flutter/material.dart';

class AppColors {
  // Formal & Clean Palette
  static const Color primary = Color(0xFF4F46E5); // Modern Indigo
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color accent = Color(0xFF06B6D4); // Soft Cyan
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  // Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  
  static const List<Color> subjectColors = [
    Color(0xFF4F46E5),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      surface: AppColors.darkCard,
    ),
    scaffoldBackgroundColor: AppColors.darkSurface,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: AppColors.darkSurface,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );
}
