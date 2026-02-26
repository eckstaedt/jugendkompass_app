import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/user_preferences_service.dart';

/// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Load theme mode from preferences
  Future<void> _loadThemeMode() async {
    final isDarkMode = UserPreferencesService.instance.getDarkMode();
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggle between light and dark mode
  Future<void> toggle() async {
    if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await UserPreferencesService.instance.setDarkMode(mode == ThemeMode.dark);
  }

  /// Check if dark mode is enabled
  bool get isDarkMode => state == ThemeMode.dark;
}
