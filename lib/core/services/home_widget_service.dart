import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:home_widget/home_widget.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'dart:developer' as developer;

/// Service to sync verse data with the Home Screen Widget (iOS & Android).
///
/// Uses the `home_widget` package to communicate with the native
/// widget implementations.
class HomeWidgetService {
  static const String _appGroupId = 'group.io.stephanus.jugendkompass';
  static const String _iOSWidgetName = 'VerseWidget';
  static const String _androidWidgetName = 'VerseWidgetProvider';

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isSupported => _isIOS || _isAndroid;

  /// Initialize the home widget service.
  static Future<void> initialize() async {
    if (_isIOS) {
      await HomeWidget.setAppGroupId(_appGroupId);
    }
  }

  /// Update the widget with the latest verse data.
  static Future<void> updateVerseWidget(VerseModel verse) async {
    if (!_isSupported) return;

    try {
      // Save verse data to shared storage
      await Future.wait([
        HomeWidget.saveWidgetData<String>('verse_text', verse.verse),
        HomeWidget.saveWidgetData<String>('verse_reference', verse.reference),
      ]);

      // Tell the OS to refresh the widget
      if (_isIOS) {
        await HomeWidget.updateWidget(iOSName: _iOSWidgetName);
      } else if (_isAndroid) {
        await HomeWidget.updateWidget(androidName: _androidWidgetName);
      }

      developer.log(
        'Home widget updated with verse: ${verse.reference}',
        name: 'HomeWidgetService',
      );
    } catch (e) {
      developer.log(
        'Failed to update home widget: $e',
        name: 'HomeWidgetService',
        level: 900,
      );
    }
  }
}
