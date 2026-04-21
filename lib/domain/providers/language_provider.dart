import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/core/services/device_registration_service.dart';
import 'package:jugendkompass_app/core/services/translation_service.dart';

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
      state = newLanguage;
      AppTranslations.setLanguage(newLanguage);
    } catch (e) {
      state = AppLanguage.de;
      AppTranslations.setLanguage(AppLanguage.de);
    }
  }

  /// Set language
  Future<void> setLanguage(AppLanguage language) async {
    print('🌐 Setting language to: ${language.displayName}');
    state = language;
    AppTranslations.setLanguage(language);
    await UserPreferencesService.instance.setLanguage(language.locale.languageCode);

    // Sync language to device_tokens table for push notifications
    await DeviceRegistrationService.instance.updateLanguage(
      language.locale.languageCode,
    );

    // Clear translation cache when switching languages
    TranslationService.instance.clearCache();

    print('✅ Language set to: ${language.displayName}');
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
