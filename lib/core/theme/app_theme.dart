import 'package:flutter/material.dart';

class AppTheme {
  // Modern Color Palette - Dark Blue & White
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color softBlue = Color(0xFFEFF6FF);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // Status Colors - Soft modern
  static const Color statusOpenColor = Color(0xFF3B82F6);
  static const Color statusAssignedColor = Color(0xFFF59E0B);
  static const Color statusInProgressColor = Color(0xFF8B5CF6);
  static const Color statusResolvedColor = Color(0xFF10B981);
  static const Color statusClosedColor = Color(0xFF64748B);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      secondary: secondaryBlue,
      surface: surfaceLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      hintStyle: TextStyle(color: Colors.grey.shade400),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: primaryBlue,
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryBlue,
      unselectedLabelColor: textSecondary,
      indicatorColor: primaryBlue,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      indicatorColor: primaryBlue.withValues(alpha: 0.1),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: lightBlue,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      primary: lightBlue,
      secondary: accentBlue,
      surface: surfaceDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightBlue, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: lightBlue,
      unselectedLabelColor: Colors.white60,
      indicatorColor: lightBlue,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceDark,
      elevation: 0,
      indicatorColor: lightBlue.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );

  static Color getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return statusOpenColor;
      case 'Assigned':
        return statusAssignedColor;
      case 'In Progress':
        return statusInProgressColor;
      case 'Resolved':
        return statusResolvedColor;
      case 'Closed':
        return statusClosedColor;
      default:
        return Colors.grey;
    }
  }
}