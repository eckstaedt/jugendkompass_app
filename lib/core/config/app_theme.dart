import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette - Basierend auf Design-Screenshots
  static const Color primaryColor = Color(0xFF8B3A3A); // Dunkelrot/Braun
  static const Color secondaryColor = Color(0xFFD4896B); // Orange/Braun
  static const Color accentColor = Color(0xFFE8A87C); // Warmes Orange

  static const Color backgroundBeige = Color(0xFFFAF3F0); // Rosa/Beige Background
  static const Color textDark = Color(0xFF1A1A2E); // Sehr dunkles Blau/Schwarz
  static const Color textGray = Color(0xFF6B7280); // Grau für Subtitles
  static const Color successGreen = Color(0xFF10B981); // Grün für Success/Online

  // Section Header Style (ALL CAPS)
  static const TextStyle sectionHeaderStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: Color(0xFF8B3A3A),
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundBeige,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFF5E6E0),
    ),

    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textDark,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      headlineMedium: TextStyle(
        color: textDark,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      headlineSmall: TextStyle(
        color: textDark,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      titleLarge: TextStyle(
        color: textDark,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      bodyLarge: TextStyle(
        color: textDark,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: textDark,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: textGray,
        fontSize: 12,
      ),
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),

    // Card Theme
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    ),

    // Button Themes
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 3,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(size: 28);
        }
        return const IconThemeData(size: 24);
      }),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      secondary: secondaryColor,
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),

    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 3,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(size: 28);
        }
        return const IconThemeData(size: 24);
      }),
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
