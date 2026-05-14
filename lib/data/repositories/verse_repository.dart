import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';

class VerseRepository {
  final SupabaseClient _supabase;

  VerseRepository(this._supabase);

  Future<VerseModel?> getTodaysVerse() async {
    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Get verse from verse_of_the_day table for today's date
      final response = await _supabase
          .from(SupabaseConstants.verseOfTheDayTable)
          .select()
          .eq('date', todayStr)
          .maybeSingle();

      if (response != null) {
        return VerseModel.fromJson(response);
      }

      // If no verse for today, get the most recent one
      final latestResponse = await _supabase
          .from(SupabaseConstants.verseOfTheDayTable)
          .select()
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latestResponse != null) {
        return VerseModel.fromJson(latestResponse);
      }

      return null;
    } catch (e) {
      throw Exception('Fehler beim Laden des Tagesverses: $e');
    }
  }

  Future<List<VerseModel>> getRecentVerses({int limit = 10}) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.verseOfTheDayTable)
          .select()
          .order('date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => VerseModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Fehler beim Laden der Verse: $e');
    }
  }

  /// Get today's verse localized using Supabase RPC function.
  ///
  /// Uses get_verse_of_day_localized(lang) which returns verse with
  /// translated verse and reference fields. German (de) returns original.
  Future<VerseModel?> getTodaysVerseLocalized(String language) async {
    try {
      // For German, use regular method
      if (language == 'de') {
        return getTodaysVerse();
      }

      final response = await _supabase.rpc(
        'get_verse_of_day_localized',
        params: {'lang': language},
      );

      if (response == null || (response is List && response.isEmpty)) {
        // Fallback to German if no translation
        return getTodaysVerse();
      }

      // RPC returns a list, get the first (today's) verse
      final verseData = response is List ? response.first : response;
      final verse = VerseModel.fromJson(verseData);

      return verse;
    } catch (e) {
      // Fallback to German on error
      return getTodaysVerse();
    }
  }

  /// Get recent verses localized.
  Future<List<VerseModel>> getRecentVersesLocalized(
    String language, {
    int limit = 10,
  }) async {
    try {
      // For German, use regular method
      if (language == 'de') {
        return getRecentVerses(limit: limit);
      }

      final response = await _supabase.rpc(
        'get_recent_verses_localized',
        params: {'lang': language, 'verse_limit': limit},
      );

      if (response == null || (response is List && response.isEmpty)) {
        // Fallback to German if no translations
        return getRecentVerses(limit: limit);
      }

      final verses = (response as List)
          .map((json) => VerseModel.fromJson(json))
          .toList();

      return verses;
    } catch (e) {
      // Fallback to German on error
      return getRecentVerses(limit: limit);
    }
  }

  /// Get a specific verse by ID with localization.
  Future<VerseModel?> getVerseByIdLocalized(String verseId, String language) async {
    try {
      // For German, use regular method
      if (language == 'de') {
        return getVerseById(verseId);
      }

      // Get the verse first
      final verse = await getVerseById(verseId);
      if (verse == null || verse.contentId == null) {
        return verse;
      }

      // Use tr() RPC function to get translated verse and reference
      try {
        final translatedVerse = await _supabase.rpc(
          'tr',
          params: {
            'content_id': verse.contentId,
            'lang': language,
            'field': 'verse',
            'fallback': verse.verse,
          },
        );

        final translatedReference = await _supabase.rpc(
          'tr',
          params: {
            'content_id': verse.contentId,
            'lang': language,
            'field': 'reference',
            'fallback': verse.reference,
          },
        );

        return VerseModel(
          id: verse.id,
          contentId: verse.contentId,
          verse: translatedVerse ?? verse.verse,
          reference: translatedReference ?? verse.reference,
          date: verse.date,
        );
      } catch (e) {
        // If translation fails, return original verse
        return verse;
      }
    } catch (e) {
      // Fallback to German on error
      return getVerseById(verseId);
    }
  }

  /// Get a specific verse by ID.
  Future<VerseModel?> getVerseById(String verseId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.verseOfTheDayTable)
          .select()
          .eq('id', verseId)
          .maybeSingle();

      if (response != null) {
        return VerseModel.fromJson(response);
      }

      return null;
    } catch (e) {
      throw Exception('Fehler beim Laden des Verses: $e');
    }
  }
}
