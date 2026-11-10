import 'package:flutter/material.dart';

/// Typography helpers.
///
/// The app uses exactly two typefaces:
///   * **Inter** (bundled in `assets/fonts/`) for the whole UI.
///   * **Merriweather** (via google_fonts) only for Bible texts.
class AppFonts {
  AppFonts._();

  static const String ui = 'Inter';

  /// Inter style with the same call shape as `GoogleFonts.inter(...)`, so it
  /// can replace former Poppins/Inter google_fonts calls one to one.
  static TextStyle uiStyle({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return (textStyle ?? const TextStyle()).copyWith(
      fontFamily: ui,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }
}
