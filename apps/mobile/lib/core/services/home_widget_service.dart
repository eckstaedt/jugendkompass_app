import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:home_widget/home_widget.dart';
import 'package:jugendkompass_app/core/config/env_config.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'dart:developer' as developer;

/// Syncs the "Vers des Tages" home-screen widget (iOS & Android).
///
/// The native widgets load today's verse themselves in the background
/// (translation + nature photo straight from Supabase), so they update even
/// when the app is not opened. For that the app hands over:
///   * `supabase_url` / `supabase_anon_key` – public read access
///   * `app_language` – the widget shows the verse in the app language
/// The last verse shown in the app is stored too, as an offline fallback.
class HomeWidgetService {
  static const String _appGroupId = 'group.io.stephanus.jugendkompass';
  static const String _iOSWidgetName = 'VerseWidget';
  static const String _androidWidgetName = 'VerseWidgetProvider';

  static bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _isSupported => _isIOS || _isAndroid;

  /// Initialize the home widget service and hand over the configuration.
  static Future<void> initialize() async {
    if (!_isSupported) return;
    try {
      if (_isIOS) await HomeWidget.setAppGroupId(_appGroupId);
      await Future.wait([
        HomeWidget.saveWidgetData<String>('supabase_url', EnvConfig.supabaseUrl),
        HomeWidget.saveWidgetData<String>('supabase_anon_key', EnvConfig.supabaseAnonKey),
        HomeWidget.saveWidgetData<String>(
          'app_language',
          UserPreferencesService.instance.getLanguage(),
        ),
      ]);
      await _refresh();
    } catch (e) {
      developer.log('Home widget init failed: $e', name: 'HomeWidgetService', level: 900);
    }
  }

  /// Called when the app language changes – the widget switches language.
  static Future<void> setLanguage(String languageCode) async {
    if (!_isSupported) return;
    try {
      await HomeWidget.saveWidgetData<String>('app_language', languageCode);
      await _refresh();
    } catch (e) {
      developer.log('Home widget language update failed: $e', name: 'HomeWidgetService', level: 900);
    }
  }

  /// Update the widget with the verse the app currently shows (localized).
  static Future<void> updateVerseWidget(VerseModel verse) async {
    if (!_isSupported) return;
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>('verse_text', verse.verse),
        HomeWidget.saveWidgetData<String>('verse_reference', verse.reference),
        HomeWidget.saveWidgetData<String>('verse_date', verse.date.toIso8601String().substring(0, 10)),
        HomeWidget.saveWidgetData<String>(
          'app_language',
          UserPreferencesService.instance.getLanguage(),
        ),
      ]);
      await _refresh();
      developer.log('Home widget updated with verse: ${verse.reference}', name: 'HomeWidgetService');
    } catch (e) {
      developer.log('Failed to update home widget: $e', name: 'HomeWidgetService', level: 900);
    }
  }

  static Future<void> _refresh() async {
    if (_isIOS) {
      await HomeWidget.updateWidget(iOSName: _iOSWidgetName);
    } else if (_isAndroid) {
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        qualifiedAndroidName: 'io.stephanus.jugendkompass.VerseWidgetProvider',
      );
    }
  }
}
