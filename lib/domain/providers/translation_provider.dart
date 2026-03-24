import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/services/translation_service.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';

/// Provides the [TranslationService] singleton.
final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService.instance;
});

/// Family provider: translates a single text string to the current language.
///
/// Usage:
/// ```dart
/// final translated = ref.watch(translateTextProvider('Hallo Welt'));
/// ```
/// The provider automatically re-evaluates (and re-fetches) when the
/// app language changes.
final translateTextProvider =
    FutureProvider.family<String, String>((ref, text) async {
  final language = ref.watch(languageProvider);
  final service = ref.watch(translationServiceProvider);
  return service.translate(text, language);
});

/// Convenience provider: returns a function `(String? text) → Future<String>`
/// bound to the current language.  Useful in widgets that need to translate
/// several fields manually.
final contentTranslatorProvider =
    Provider<Future<String> Function(String?)>((ref) {
  final language = ref.watch(languageProvider);
  final service = ref.watch(translationServiceProvider);
  return (String? text) => service.translate(text, language);
});

/// Translates a [VerseModel]-like record: returns translated verse + reference.
final translateVerseProvider = FutureProvider.family<
    ({String verse, String reference}),
    ({String verse, String reference})>((ref, data) async {
  final language = ref.watch(languageProvider);
  if (language == AppLanguage.de) {
    return data;
  }
  final service = ref.watch(translationServiceProvider);
  final verse = await service.translate(data.verse, language);
  final reference = await service.translate(data.reference, language);
  return (verse: verse, reference: reference);
});

/// Translates an impulse's text fields.
final translateImpulseProvider = FutureProvider.family<
    ({String title, String impulseText}),
    ({String id, String title, String impulseText})>((ref, data) async {
  final language = ref.watch(languageProvider);
  if (language == AppLanguage.de) {
    return (title: data.title, impulseText: data.impulseText);
  }
  final service = ref.watch(translationServiceProvider);
  final title = await service.translate(data.title, language);
  final impulseText = await service.translate(data.impulseText, language);
  return (title: title, impulseText: impulseText);
});

/// Translates a post's title and body fields.
final translatePostProvider = FutureProvider.family<
    ({String title, String body}),
    ({String id, String title, String body})>((ref, data) async {
  final language = ref.watch(languageProvider);
  if (language == AppLanguage.de) {
    return (title: data.title, body: data.body);
  }
  final service = ref.watch(translationServiceProvider);
  final title = await service.translate(data.title, language);
  final body = await service.translate(data.body, language);
  return (title: title, body: body);
});
