import 'package:flutter/material.dart';

/// Zentrale Design Tokens für konsistentes UI-Design
class DesignTokens {
  // ⸻ FARBPALETTE
  static const Color primaryRed = Color(0xFF8B0000);
  static const Color primaryRedActive = Color(0xFF7A0000);
  static const Color redBackground = Color(0xFFF2DCDC);
  
  static const Color appBackground = Color(0xFFE9E9EB);
  static const Color cardBackground = Color(0xFFF4F4F6);
  
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6F7479);
  static const Color iconGrey = Color(0xFF9AA0A6);

  // ⸻ BORDER RADIUS SYSTEM
  static const double radiusLargeCards = 32;
  static const double radiusMiddleContainers = 24;
  static const double radiusButtons = 20;
  static const double radiusInputFields = 18;
  static const double radiusBadges = 50;
  static const double radiusFloatingButton = 100;

  // ⸻ SHADOW SYSTEM - Soft & Modern
  
  // Große Cards - Weiches Shadow
  static BoxShadow shadowLargeCard = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 25,
    offset: const Offset(0, 15),
  );

  // Buttons - Primary Red Shadow
  static BoxShadow shadowButton = BoxShadow(
    color: primaryRed.withOpacity(0.35),
    blurRadius: 20,
    offset: const Offset(0, 10),
  );

  // Icon Container - Kräftiges Glow
  static BoxShadow shadowIconContainer = BoxShadow(
    color: primaryRed.withOpacity(0.4),
    blurRadius: 35,
    offset: const Offset(0, 20),
  );

  // Minimales Shadow für subtile Elevation
  static BoxShadow shadowSubtle = BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  // ⸻ SPACING SYSTEM
  static const double spacingSmall = 16; // small gaps
  static const double spacingMedium = 24; // medium gaps (used between major elements)
  static const double spacingLarge = 48; // large gaps
  static const double paddingHorizontal = 24;
  static const double paddingVertical = 24;

  // Input background color used across app
  static const Color inputBackground = Color(0xFFE1E3E6);

  // Success / Positive color (used in search results etc.)
  static const Color successGreen = Color(0xFF2E7D32);

  // Glass effect background used for translucent containers (liquid glass)
  // not const because we apply opacity dynamically
  static Color glassBackground([double opacity = 0.15]) =>
      Colors.white.withOpacity(opacity);

  // Recommended blur sigma for backdrop filter when using glass effect
  static const double glassBlurSigma = 20.0;

  // ⸻ BUTTON DIMENSIONS
  static const double buttonHeight = 56;
  static const double floatingButtonSize = 56;

  // ⸻ TYPOGRAPHY HELPER
  static TextStyle headlineStyle = const TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 30,
    color: textPrimary,
    fontFamily: 'Inter',
  );

  static TextStyle cardTitleStyle = const TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: textPrimary,
    fontFamily: 'Inter',
  );

  static TextStyle bodyTextStyle = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: textPrimary,
    fontFamily: 'Inter',
    height: 1.4,
  );

  static TextStyle captionStyle = const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 13,
    letterSpacing: 1.2,
    color: textSecondary,
    fontFamily: 'Inter',
  );
}
