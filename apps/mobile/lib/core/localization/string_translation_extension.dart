import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/localization/string_translator.dart';

/// Extension on String for automatic translation
extension StringTranslationExtension on String {
  /// Translates the string from German to the current language
  /// Usage: "Fehler".translated
  String get translated => StringTranslator.translate(this, AppTranslations.currentLanguage);
}
