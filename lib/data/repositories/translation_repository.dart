import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';

/// Repository for fetching content translations from Supabase.
///
/// German (de) is the source language stored in original tables.
/// Translations for other languages (en, es, ru, pl, tr) are stored
/// in the content_translations table.
class TranslationRepository {
  final SupabaseClient _supabase;

  TranslationRepository(this._supabase);

  /// Fetch all translations for a specific content_id.
  ///
  /// Returns a map: { 'en': { 'title': '...', 'body': '...' }, 'ru': { ... } }
  Future<Map<String, Map<String, String>>> getTranslations(
    String contentId,
    List<String> languages,
  ) async {
    try {
      final response = await _supabase
          .from('content_translations')
          .select('language, field_name, value')
          .eq('content_id', contentId)
          .in_('language', languages);

      final Map<String, Map<String, String>> translations = {};

      for (final row in response as List) {
        final lang = row['language'] as String;
        final field = row['field_name'] as String;
        final value = row['value'] as String;

        if (!translations.containsKey(lang)) {
          translations[lang] = {};
        }
        translations[lang]![field] = value;
      }

      return translations;
    } catch (e) {
      throw Exception('Fehler beim Laden der Übersetzungen: $e');
    }
  }

  /// Get a specific translated field with fallback to German.
  ///
  /// Priority: requested language → German fallback
  String getTranslatedField(
    Map<String, dynamic>? translations,
    String language,
    String fieldName,
    String germanFallback,
  ) {
    // If German is requested, return fallback directly
    if (language == 'de') return germanFallback;

    // Try to get translation for requested language
    if (translations != null && translations.containsKey(language)) {
      final langTranslations = translations[language] as Map<String, dynamic>?;
      if (langTranslations != null && langTranslations.containsKey(fieldName)) {
        return langTranslations[fieldName] as String;
      }
    }

    // Fallback to German
    return germanFallback;
  }

  /// Call Supabase RPC function to get localized content.
  ///
  /// This is the preferred method as it handles translations server-side.
  Future<List<Map<String, dynamic>>> getLocalizedContent(
    String functionName,
    String language,
  ) async {
    try {
      final response = await _supabase.rpc(
        functionName,
        params: {'lang': language},
      );

      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Fehler beim Laden von lokalisiertem Inhalt: $e');
    }
  }

  /// Call Supabase RPC function with additional parameters.
  Future<List<Map<String, dynamic>>> getLocalizedContentWithParams(
    String functionName,
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await _supabase.rpc(functionName, params: params);
      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Fehler beim Laden von lokalisiertem Inhalt: $e');
    }
  }
}
