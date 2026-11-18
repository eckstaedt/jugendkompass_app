import 'package:flutter/material.dart';

/// Utility class for showing consistent SnackBar messages throughout the app.
class SnackBarUtils {
  SnackBarUtils._();

  /// Show a snackbar. By default it appears at the top of the screen,
  /// pass [topPosition] = false to show it at the bottom, above the
  /// bottom navigation bar instead.
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool topPosition = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: topPosition
            ? EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 150,
                left: 16,
                right: 16,
              )
            : const EdgeInsets.only(
                bottom: 90,
                left: 16,
                right: 16,
              ),
      ),
    );
  }

  /// Show an error snackbar at the top
  static void showError(BuildContext context, String message) {
    show(context, message, backgroundColor: Colors.red);
  }

  /// Show a success snackbar at the top
  static void showSuccess(BuildContext context, String message) {
    show(context, message, backgroundColor: Colors.green);
  }

  /// Show a success snackbar at the bottom, above the navigation bar.
  static void showSuccessBottom(BuildContext context, String message) {
    show(context, message, backgroundColor: Colors.green, topPosition: false);
  }
}
