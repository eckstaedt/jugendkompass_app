import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/data/services/content_localizer.dart';

class AudioRepository {
  final SupabaseClient _supabase;

  AudioRepository(this._supabase) : _localizer = ContentLocalizer.forClient(_supabase);

  final ContentLocalizer _localizer;

  static String get _currentLanguage => AppTranslations.currentLanguage.locale.languageCode;

  /// Builds AudioModels from `audios` rows joined with `posts`, translating the
  /// joined post (title/body/categories) into [language].
  Future<List<AudioModel>> _toAudioModels(List rows, String language) async {
    final mapped = <Map<String, dynamic>>[];
    final posts = <Map<String, dynamic>>[];
    for (final raw in rows) {
      final json = Map<String, dynamic>.from(raw as Map);
      final joined = json['posts'];
      Map<String, dynamic>? postData;
      if (joined is List && joined.isNotEmpty) {
        postData = Map<String, dynamic>.from(joined[0] as Map);
      } else if (joined is Map) {
        postData = Map<String, dynamic>.from(joined);
      }
      if (postData != null) {
        postData['audio_id'] = json['id'];
        posts.add(postData);
      }
      mapped.add({'id': json['id'], 'url': json['url'], 'created_at': json['created_at'], 'post': postData});
    }

    await _localizer.localizeContentRows(posts, language, fields: const {'title': 'title', 'body': 'body'});
    await _localizer.localizeNestedCategories(posts, language);
    await _localizer.localizeAudioUrls(mapped, language);

    return mapped.map(AudioModel.fromJson).toList();
  }

  /// Get audio list with localized metadata from posts table
  Future<List<AudioModel>> getAudioListLocalized(String language, {
    String? categoryId,
    int limit = 1000,
    int offset = 0,
  }) {
    return getAudioList(categoryId: categoryId, limit: limit, offset: offset, language: language);
  }

  /// Get audio list with metadata from posts table
  /// Joins audios with posts where posts.audio_id = audios.id
  Future<List<AudioModel>> getAudioList({
    String? categoryId,
    int limit = 1000,
    int offset = 0,
    String? language,
  }) async {
    try {
      // Join audios with posts to get full post data
      final query = _supabase
          .from(SupabaseConstants.audiosTable)
          .select('''
            id,
            url,
            created_at,
            posts!audio_id(
              id,
              title,
              created_at,
              body,
              image_url,
              category_id,
              content_id,
              edition_id,
              categories(
                id,
                name
              )
            )
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;

      return _toAudioModels(response as List, language ?? _currentLanguage);
    } catch (e) {
      throw Exception('Fehler beim Laden der Audios: $e');
    }
  }

  /// Get audio by ID with metadata from posts table
  Future<AudioModel?> getAudioById(String id, {String? language}) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.audiosTable)
          .select('''
            id,
            url,
            posts!audio_id(
              id,
              title,
              body,
              image_url,
              category_id,
              content_id,
              edition_id,
              categories(
                id,
                name
              )
            )
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      final models = await _toAudioModels([response], language ?? _currentLanguage);
      return models.first;
    } catch (e) {
      throw Exception('Fehler beim Laden des Audios: $e');
    }
  }

  /// Get recommended audios based on category
  Future<List<AudioModel>> getRecommendedAudios({
    String? categoryId,
    String? excludeAudioId,
    int limit = 10,
    String? language,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConstants.audiosTable)
          .select('''
            id,
            url,
            posts!audio_id(
              id,
              title,
              body,
              image_url,
              category_id,
              content_id,
              edition_id,
              categories(
                id,
                name
              )
            )
          ''');

      // Exclude current audio if provided
      if (excludeAudioId != null) {
        query = query.neq('id', excludeAudioId);
      }

      final response = await query.limit(limit);

      var audioList = await _toAudioModels(response as List, language ?? _currentLanguage);

      // Filter by category if provided
      if (categoryId != null) {
        audioList = audioList.where((audio) {
          return audio.post?.categoryId == categoryId;
        }).toList();
      }

      // Return up to limit items
      return audioList.take(limit).toList();
    } catch (e) {
      throw Exception('Fehler beim Laden der Empfehlungen: $e');
    }
  }
}
