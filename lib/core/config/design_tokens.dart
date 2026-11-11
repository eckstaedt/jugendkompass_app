import 'package:flutter/material.dart';

/// Zentrale Design Tokens für konsistentes UI-Design
class DesignTokens {
  // ⸻ FARBPALETTE - LIGHT MODE
  // Juicy, friendly red – the same red everywhere in the app.
  static const Color primaryRed = Color(0xFFE23B44);
  static const Color primaryRedActive = Color(0xFFC92F38);
  /// Readable red for text/links on dark backgrounds.
  static const Color primaryRedOnDark = Color(0xFFFF7D84);
  static const Color redBackground = Color(0xFFFFE3E5);
  
  static const Color appBackground = Color(0xFFF0F0F3);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6F7479);
  static const Color iconGrey = Color(0xFF9AA0A6);

  // Neutral chip / tag colors (red is reserved for primary actions and the
  // active state).
  static const Color chipBackground = Color(0xFFECEDEF);
  static const Color darkChipBackground = Color(0xFF2A2A2C);

  static Color getChipBackground(Brightness brightness) =>
      brightness == Brightness.dark ? darkChipBackground : chipBackground;

  // Badge colors
  static const Color pollBadgeColor = Color(0xFF7C3AED); // Purple for polls
  static const Color successColor = Color(0xFF10B981); // Green for success states

  // ⸻ FARBPALETTE - DARK MODE
  static const Color darkAppBackground = Color(0xFF0A0A0A);
  static const Color darkCardBackground = Color(0xFF1A1A1A);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkIconGrey = Color(0xFF707070);

  // Dark mode badge colors
  static const Color darkPollBadgeColor = Color(0xFF9F7AEA); // Lighter purple for dark mode
  static const Color darkSuccessColor = Color(0xFF34D399); // Lighter green for dark mode

  // Dark mode red background (more visible for dark theme)
  static const Color darkRedBackground = Color(0xFF552026);

  // ⸻ BORDER RADIUS SYSTEM
  // Three steps only – small (12), medium (16), large (24) – so shapes feel
  // deliberate instead of "everything maximally rounded".
  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 24;

  static const double radiusLargeCards = radiusLarge; // big cards, search bar
  static const double radiusMiddleContainers = radiusMedium; // tiles, images, list cards
  static const double radiusButtons = radiusMedium;
  static const double radiusInputFields = radiusSmall;
  static const double radiusBadges = 6; // small tag shape, not a pill
  static const double radiusFloatingButton = 100; // Perfect circles
  static const double radiusNavBar = 40; // floating pill navbar
  /// The verse-of-the-day card keeps its original, larger radius.
  static const double radiusVerseCard = 40;

  // ⸻ SHADOW SYSTEM - iOS 26 Liquid Glass Aesthetic
  
  // Große Cards - Weiches Shadow
  static BoxShadow shadowLargeCard = BoxShadow(
    color: Colors.black.withOpacity(0.10),
    blurRadius: 24,
    offset: const Offset(0, 8),
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
    color: Colors.black.withOpacity(0.07),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  // iOS 26 Glass shadow - Subtle elevation for glass cards
  static BoxShadow shadowGlass = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  // ⸻ SPACING SYSTEM
  static const double spacingSmall = 16; // small gaps
  static const double spacingMedium = 24; // medium gaps (used between major elements)
  static const double spacingLarge = 48; // large gaps
  static const double paddingHorizontal = 24;
  static const double paddingVertical = 24;

  // ⸻ OVERLAY BOTTOM PADDING
  // Extra bottom padding to prevent persistent navbar + mini player from
  // covering scrollable content. Use these in every scrollable screen.
  //
  // navbarOverlayHeight: navbar (60) + top margin (4) + extra clearance (16) = 80
  // miniPlayerHeight: mini player bar (72) + gap (8) = 80
  //
  // When ONLY navbar is visible: overlayPaddingBase
  // When BOTH navbar + mini player visible: overlayPaddingWithMiniPlayer
  static const double overlayPaddingBase = 120;
  static const double overlayPaddingWithMiniPlayer = 200;

  // Input background color used across app
  static const Color inputBackground = Color(0xFFE1E3E6);
  static const Color darkInputBackground = Color(0xFF2A2A2A);

  static Color getInputBackground(Brightness brightness) {
    return brightness == Brightness.dark ? darkInputBackground : inputBackground;
  }

  // Success / Positive color (used in search results etc.)
  static const Color successGreen = Color(0xFF2E7D32);

  // Content type tags: pastel red for reading content (article, short
  // message, impulse …), pastel green for media (audio, video).
  static Color getReadingTagBackground(Brightness b) =>
      b == Brightness.dark ? const Color(0x47E23B44) : redBackground;
  static Color getReadingTagText(Brightness b) =>
      b == Brightness.dark ? primaryRedOnDark : primaryRed;
  static Color getMediaTagBackground(Brightness b) =>
      b == Brightness.dark ? const Color(0x4066BB6A) : const Color(0xFFDDF3E3);
  static Color getMediaTagText(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFA8DDB4) : const Color(0xFF2E7D4F);

  // Glass effect background used for translucent containers (liquid glass - iOS 26 style)
  // Dynamic based on brightness
  static Color glassBackground([double opacity = 0.18]) =>
    Colors.white.withValues(alpha: opacity);

  // Dark mode glass background - uses white with higher opacity for frosted glass on dark
  static Color glassDarkBackground([double opacity = 0.20]) =>
    Colors.white.withValues(alpha: opacity * 0.7);

  /// Standard card border for consistent contrast across the app.
  /// Use this for ALL card-like elements.
  static Border cardBorder(Brightness brightness) {
    return Border.all(
      color: brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08),
      width: 1,
    );
  }

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

  /// Body text for long reading (darker than secondary text).
  static const Color textBody = Color(0xFF2E3236);
  static const Color darkTextBody = Color(0xFFDADADA);

  static Color getTextBody(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextBody : textBody;
  }

  static Color getTextSecondary(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextSecondary : textSecondary;
  }

  static Color getRedBackground(Brightness brightness) {
    return brightness == Brightness.dark ? darkRedBackground : redBackground;
  }

  static Color getPollBadgeColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkPollBadgeColor : pollBadgeColor;
  }

  static Color getSuccessColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkSuccessColor : successColor;
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

  // ⸻ TYPOGRAPHY HELPER (prefer theme.textTheme for dark mode support)
  static TextStyle headlineStyle = const TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 30,
    color: textPrimary,
    fontFamily: 'Inter',
  );

  static TextStyle getHeadlineStyle(Brightness brightness) => TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 30,
    color: getTextPrimary(brightness),
    fontFamily: 'Inter',
  );

  static TextStyle cardTitleStyle = const TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: textPrimary,
    fontFamily: 'Inter',
  );

  static TextStyle getCardTitleStyle(Brightness brightness) => TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: getTextPrimary(brightness),
    fontFamily: 'Inter',
  );

  static TextStyle bodyTextStyle = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: textPrimary,
    fontFamily: 'Inter',
    height: 1.4,
  );

  static TextStyle getBodyTextStyle(Brightness brightness) => TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: getTextPrimary(brightness),
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

  static TextStyle getCaptionStyle(Brightness brightness) => TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 13,
    letterSpacing: 1.2,
    color: getTextSecondary(brightness),
    fontFamily: 'Inter',
  );
}
