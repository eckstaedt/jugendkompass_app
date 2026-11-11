import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/core/services/device_registration_service.dart';
import 'package:jugendkompass_app/data/services/content_localizer.dart';
import 'package:jugendkompass_app/data/services/image_localizer.dart';
import 'package:jugendkompass_app/core/services/home_widget_service.dart';

/// Language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>(
  (ref) => LanguageNotifier(),
);

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.de) {
    _loadLanguage();
  }

  /// Load language from preferences
  Future<void> _loadLanguage() async {
    final languageCode = UserPreferencesService.instance.getLanguage();
    try {
      final newLanguage = AppLanguage.values.firstWhere(
        (lang) => lang.locale.languageCode == languageCode,
        orElse: () => AppLanguage.de,
      );
      // A hidden language (picked earlier) falls back to German, incl. push
      // notifications and the widget.
      if (!AppLanguage.availableLanguages.contains(newLanguage)) {
        await setLanguage(AppLanguage.de);
        return;
      }
      state = newLanguage;
      AppTranslations.setLanguage(newLanguage);
      ImageLocalizer.instance.load(newLanguage.locale.languageCode);
    } catch (e) {
      state = AppLanguage.de;
      AppTranslations.setLanguage(AppLanguage.de);
    }
  }

  /// Set language
  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    AppTranslations.setLanguage(language);
    await UserPreferencesService.instance.setLanguage(language.locale.languageCode);

    // Sync language to device_tokens table for push notifications
    await DeviceRegistrationService.instance.updateLanguage(
      language.locale.languageCode,
    );

    // Fresh content translations for the new language
    ContentLocalizer.clearSharedCache();
    // Cover images with translated text
    ImageLocalizer.instance.load(language.locale.languageCode);

    // Home-screen widget follows the app language.
    await HomeWidgetService.setLanguage(language.locale.languageCode);

  }
}

/// Translations provider
final translationsProvider = Provider((ref) {
  final language = ref.watch(languageProvider);
  return Translations(language);
});

/// Helper to get translated string
final getStringProvider = Provider.family<String, String>((ref, key) {
  return ref.watch(translationsProvider).get(key);
});
