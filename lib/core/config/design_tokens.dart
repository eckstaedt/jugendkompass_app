import 'package:flutter/material.dart';

/// Zentrale Design Tokens für konsistentes UI-Design
class DesignTokens {
  // ⸻ FARBPALETTE - LIGHT MODE
  static const Color primaryRed = Color(0xFF8B0000);
  static const Color primaryRedActive = Color(0xFF7A0000);
  static const Color redBackground = Color(0xFFF2DCDC);
  
  static const Color appBackground = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6F7479);
  static const Color iconGrey = Color(0xFF9AA0A6);

  // ⸻ FARBPALETTE - DARK MODE
  static const Color darkAppBackground = Color(0xFF121212);
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkIconGrey = Color(0xFF808080);
  
  // Dark mode red background (more muted for dark theme)
  static const Color darkRedBackground = Color(0xFF3D1515);

  // ⸻ BORDER RADIUS SYSTEM (iOS 26 Liquid Glass Design)
  static const double radiusLargeCards = 40; // Increased for flowing iOS 26 aesthetic
  static const double radiusMiddleContainers = 32; // Increased for consistency
  static const double radiusButtons = 24; // Rounded button appearance
  static const double radiusInputFields = 20; // Smooth input fields
  static const double radiusBadges = 50; // Full pill-style badges
  static const double radiusFloatingButton = 100; // Perfect circles
  static const double radiusNavBar = 40; // iOS 26 navbar radius

  // ⸻ SHADOW SYSTEM - iOS 26 Liquid Glass Aesthetic
  
  // Große Cards - Weiches Shadow (Minimal für Glass Effect)
  static BoxShadow shadowLargeCard = BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 20,
    offset: const Offset(0, 10),
  );

  // Buttons - Primary Red Shadow
  static BoxShadow shadowButton = BoxShadow(
    color: primaryRed.withOpacity(0.30),
    blurRadius: 16,
    offset: const Offset(0, 8),
  );

  // Icon Container - Kräftiges Glow
  static BoxShadow shadowIconContainer = BoxShadow(
    color: primaryRed.withOpacity(0.35),
    blurRadius: 30,
    offset: const Offset(0, 16),
  );

  // Minimales Shadow für subtile Elevation (Glass layers)
  static BoxShadow shadowSubtle = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 10,
    offset: const Offset(0, 3),
  );

  // iOS 26 Glass shadow - Ultra-subtle for glass cards
  static BoxShadow shadowGlass = BoxShadow(
    color: Colors.black.withOpacity(0.03),
    blurRadius: 8,
    offset: const Offset(0, 2),
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

  // Glass effect background used for translucent containers (liquid glass - iOS 26 style)
  // Dynamic based on brightness
  static Color glassBackground([double opacity = 0.18]) =>
    Colors.white.withValues(alpha: opacity);

  // Dark mode glass background
  static Color glassDarkBackground([double opacity = 0.15]) =>
    Colors.white.withValues(alpha: opacity);

  // Helper to get appropriate color based on brightness
  static Color getAppBackground(Brightness brightness) {
    return brightness == Brightness.dark ? darkAppBackground : appBackground;
  }

  static Color getCardBackground(Brightness brightness) {
    return brightness == Brightness.dark ? darkCardBackground : cardBackground;
  }

  static Color getTextPrimary(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextPrimary : textPrimary;
  }

  static Color getTextSecondary(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextSecondary : textSecondary;
  }

  static Color getRedBackground(Brightness brightness) {
    return brightness == Brightness.dark ? darkRedBackground : redBackground;
  }

  static Color getGlassBackground(Brightness brightness, [double opacity = 0.18]) {
    if (brightness == Brightness.dark) {
      return glassDarkBackground(opacity);
    } else {
      return glassBackground(opacity);
    }
  }

  // Recommended blur sigma for backdrop filter when using glass effect (iOS 26)
  // reduce blur so containers stand out from background more clearly
  static const double glassBlurSigma = 16.0;

  // Secondary glass opacities for depth layering
  static Color glassBackgroundDeep([double opacity = 0.18]) =>
      Colors.white.withValues(alpha: opacity);
  
  static Color glassBackgroundShallow([double opacity = 0.08]) =>
      Colors.white.withValues(alpha: opacity);

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
