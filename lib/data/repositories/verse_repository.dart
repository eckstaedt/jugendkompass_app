import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';
import 'package:jugendkompass_app/data/services/content_localizer.dart';

class VerseRepository {
  final SupabaseClient _supabase;

  VerseRepository(this._supabase) : _localizer = ContentLocalizer.forClient(_supabase);

  final ContentLocalizer _localizer;

  static const _fields = {'verse': 'verse', 'reference': 'reference'};

  /// Overlays translated verse text and Bible reference.
  Future<List<VerseModel>> localizeVerses(List<VerseModel> verses, String language) async {
    if (!ContentLocalizer.needsTranslation(language) || verses.isEmpty) return verses;
    final rows = await _localizer.localizeContentRows(
      [
        for (final v in verses) {'content_id': v.contentId, 'verse': v.verse, 'reference': v.reference},
      ],
      language,
      fields: _fields,
    );
    return [
      for (var i = 0; i < verses.length; i++)
        verses[i].copyWith(
          verse: rows[i]['verse'] as String?,
          reference: rows[i]['reference'] as String?,
        ),
    ];
  }

  Future<VerseModel?> _localizeOne(VerseModel? verse, String language) async {
    if (verse == null) return null;
    return (await localizeVerses([verse], language)).first;
  }

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

  /// Get today's verse localized (German row + translation overlay).
  Future<VerseModel?> getTodaysVerseLocalized(String language) async {
    return _localizeOne(await getTodaysVerse(), language);
  }

  /// Get recent verses localized.
  Future<List<VerseModel>> getRecentVersesLocalized(
    String language, {
    int limit = 10,
  }) async {
    return localizeVerses(await getRecentVerses(limit: limit), language);
  }

  /// Get a specific verse by ID with localization.
  Future<VerseModel?> getVerseByIdLocalized(String verseId, String language) async {
    return _localizeOne(await getVerseById(verseId), language);
  }

  /// Increment the usage counter for a verse (share or save-to-gallery).
  /// Fire-and-forget: errors are swallowed so UI flow is never blocked.
  Future<void> incrementUsage(String verseId) async {
    try {
      await _supabase.rpc(
        'increment_verse_usage',
        params: {'verse_id': verseId},
      );
    } catch (_) {
      // Counter is best-effort; ignore failures.
    }
  }

  /// Get a paginated archive of ALL verse-of-the-day entries (newest first),
  /// localized for the given language. Includes `image_url` so the UI can
  /// determine whether a verse is shareable as an image.
  ///
  /// Only verses up to and including today are returned - future-dated
  /// (pre-scheduled) verses are excluded so the archive never spoils
  /// upcoming daily verses.
  ///
  /// Used by the "Vers des Tages Archiv" screen for infinite scroll.
  Future<List<VerseModel>> getVerseArchive(
    String language, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from(SupabaseConstants.verseOfTheDayTable)
          .select()
          .lte('date', todayStr)
          .order('date', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final verses = (response as List)
          .map((json) => VerseModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return await localizeVerses(verses, language);
    } catch (e) {
      throw Exception('Fehler beim Laden des Vers-Archivs: $e');
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

  /// Get a specific verse by its content_id (FK to the polymorphic `content`
  /// table). Used for deep linking from push notifications.
  Future<VerseModel?> getVerseByContentId(String contentId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.verseOfTheDayTable)
          .select()
          .eq('content_id', contentId)
          .maybeSingle();

      if (response != null) {
        return VerseModel.fromJson(response);
      }

      return null;
    } catch (e) {
      throw Exception('Fehler beim Laden des Verses: $e');
    }
  }

  /// Get a localized verse by content_id.
  Future<VerseModel?> getVerseByContentIdLocalized(String contentId, String language) async {
    return _localizeOne(await getVerseByContentId(contentId), language);
  }
}
