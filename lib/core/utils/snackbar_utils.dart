import 'package:flutter/material.dart';

/// Utility class for showing consistent SnackBar messages throughout the app.
class SnackBarUtils {
  SnackBarUtils._();

  /// Show a snackbar at the top of the screen
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
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
}
