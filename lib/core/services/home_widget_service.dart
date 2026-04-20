import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'dart:developer' as developer;

/// Service to sync verse data with the iOS Home Screen Widget.
///
/// Uses the `home_widget` package to communicate with the native
/// WidgetKit extension via App Group shared UserDefaults.
class HomeWidgetService {
  static const String _appGroupId = 'group.io.stephanus.jugendkompass';
  static const String _iOSWidgetName = 'VerseWidget';

  /// Initialize the home widget service with the App Group ID.
  static Future<void> initialize() async {
    if (kIsWeb) return;
    // Only run on iOS
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(_appGroupId);
      }
    } catch (e) {
      // Platform check may fail on web, ignore
    }
  }

  /// Update the iOS widget with the latest verse data.
  static Future<void> updateVerseWidget(VerseModel verse) async {
    if (kIsWeb) return;
    // Only run on iOS
    try {
      if (!Platform.isIOS) return;
    } catch (e) {
      // Platform check may fail on web, ignore
      return;
    }

    try {
      // Save verse data to shared UserDefaults
      await Future.wait([
        HomeWidget.saveWidgetData<String>('verse_text', verse.verse),
        HomeWidget.saveWidgetData<String>('verse_reference', verse.reference),
      ]);

      // Tell iOS to refresh the widget
      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
      );

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
