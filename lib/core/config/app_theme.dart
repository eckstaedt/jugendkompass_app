import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  // Backward Compatibility - alte Farben für Migration
  static const Color primaryColor = DesignTokens.primaryRed;
  static const Color backgroundBeige = DesignTokens.appBackground;
  static const Color textDark = DesignTokens.textPrimary;
  static const Color textGray = DesignTokens.textSecondary;
  static const Color successGreen = Color(0xFF10B981);

  // ⸻ LIGHT THEME - Modern, Soft, Premium Minimal
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: DesignTokens.appBackground,
    
    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: DesignTokens.primaryRed,
      onPrimary: Colors.white,
      secondary: Colors.grey.shade400,
      surface: DesignTokens.cardBackground,
      onSurface: DesignTokens.textPrimary,
      error: Colors.red.shade700,
    ),

    // Text Theme mit Inter Font (no google_fonts)
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: DesignTokens.textPrimary,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: DesignTokens.textPrimary,
      ),
      displaySmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: DesignTokens.textPrimary,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: DesignTokens.textPrimary,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: DesignTokens.textPrimary,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: DesignTokens.textPrimary,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: DesignTokens.textPrimary,
      ),
      titleSmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: DesignTokens.textPrimary,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: DesignTokens.textPrimary,
        height: 1.4,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: DesignTokens.textPrimary,
        height: 1.4,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: DesignTokens.textSecondary,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: DesignTokens.textPrimary,
      ),
      labelMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DesignTokens.textPrimary,
      ),
      labelSmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: DesignTokens.textSecondary,
      ),
    ),

    // AppBar Theme - Minimal
    appBarTheme: AppBarTheme(
      backgroundColor: DesignTokens.appBackground,
      foregroundColor: DesignTokens.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: DesignTokens.textPrimary,
      ),
    ),

    // Card Theme - iOS 26 Glass Aesthetic with Large Radii
    cardTheme: CardThemeData(
      color: DesignTokens.glassBackground(0.12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
      ),
      clipBehavior: Clip.antiAlias,
      shadowColor: Colors.black.withOpacity(0.04),
    ),

    // Input Decoration Theme - Sanfte Ränder
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusInputFields),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusInputFields),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusInputFields),
        borderSide: BorderSide(
          color: DesignTokens.primaryRed,
          width: 2,
        ),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: DesignTokens.textSecondary,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: DesignTokens.textPrimary,
      ),
    ),

    // Elevated Button Theme - Primary Button Style
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.primaryRed,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, DesignTokens.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
        ),
        elevation: 0,
        shadowColor: DesignTokens.primaryRed.withOpacity(0.35),
      ),
    ),

    // Filled Button Theme
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DesignTokens.primaryRed,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, DesignTokens.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DesignTokens.primaryRed,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Icon Button Theme
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: DesignTokens.iconGrey,
      ),
    ),

    // Navigation Bar Theme - Minimal, Soft
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: DesignTokens.primaryRed.withOpacity(0.1),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: DesignTokens.primaryRed,
            size: 28,
          );
        }
        return const IconThemeData(
          color: DesignTokens.iconGrey,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: DesignTokens.primaryRed,
          );
        }
        return const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: DesignTokens.textSecondary,
        );
      }),
      height: 70,
      elevation: 0,
      shadowColor: Colors.transparent,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusBadges),
      ),
      backgroundColor: DesignTokens.redBackground,
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: DesignTokens.primaryRed,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
    ),
  );

  // ⸻ DARK THEME
  // ⸻ DARK THEME - Premium Dark Minimal
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: DesignTokens.darkAppBackground,
    
    colorScheme: ColorScheme.dark(
      primary: DesignTokens.primaryRed,
      onPrimary: Colors.white,
      secondary: Colors.grey.shade600,
      surface: DesignTokens.darkCardBackground,
      onSurface: DesignTokens.darkTextPrimary,
      error: Colors.red.shade400,
    ),

    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: DesignTokens.darkTextPrimary,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: DesignTokens.darkTextPrimary,
      ),
      displaySmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: DesignTokens.darkTextPrimary,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: DesignTokens.darkTextPrimary,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: DesignTokens.darkTextPrimary,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: DesignTokens.darkTextPrimary,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: DesignTokens.darkTextPrimary,
      ),
      titleSmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: DesignTokens.darkTextPrimary,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: DesignTokens.darkTextPrimary,
        height: 1.4,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: DesignTokens.darkTextPrimary,
        height: 1.4,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: DesignTokens.darkTextSecondary,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: DesignTokens.darkTextPrimary,
      ),
      labelMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DesignTokens.darkTextPrimary,
      ),
      labelSmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: DesignTokens.darkTextSecondary,
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: DesignTokens.darkAppBackground,
      foregroundColor: DesignTokens.darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: DesignTokens.darkTextPrimary,
      ),
    ),

    cardTheme: CardThemeData(
      color: DesignTokens.darkCardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DesignTokens.darkCardBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusInputFields),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusInputFields),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusInputFields),
        borderSide: BorderSide(
          color: DesignTokens.primaryRed,
          width: 2,
        ),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: DesignTokens.darkTextSecondary,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DesignTokens.primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DesignTokens.primaryRed,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: DesignTokens.darkTextPrimary,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DesignTokens.darkCardBackground,
      indicatorColor: DesignTokens.primaryRed,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: DesignTokens.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: DesignTokens.darkTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        },
      ),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: DesignTokens.primaryRed,
            );
          }
          return const IconThemeData(
            color: DesignTokens.darkTextSecondary,
          );
        },
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: DesignTokens.darkCardBackground,
      selectedColor: DesignTokens.primaryRed,
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DesignTokens.darkTextPrimary,
      ),
      side: BorderSide(
        color: Colors.grey.shade700,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusBadges),
      ),
    ),
  );
}

