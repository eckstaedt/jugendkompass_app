import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/localization/string_translator.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';

/// Provider for string translation based on current language
final stringTranslatorProvider = Provider<String Function(String?)>((ref) {
  final language = ref.watch(languageProvider);
  
  // Return a function that translates strings using the current language
  return (String? text) => StringTranslator.autoTranslate(text, language);
});
