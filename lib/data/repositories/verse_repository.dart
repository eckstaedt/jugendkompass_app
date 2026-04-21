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
      return VerseModel.fromJson(verseData);
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
        'get_verse_of_day_localized',
        params: {'lang': language},
      );

      final verses = (response as List)
          .map((json) => VerseModel.fromJson(json))
          .toList();

      return verses.take(limit).toList();
    } catch (e) {
      // Fallback to German on error
      return getRecentVerses(limit: limit);
    }
  }
}
