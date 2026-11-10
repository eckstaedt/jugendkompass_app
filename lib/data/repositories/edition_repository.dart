import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/edition_model.dart';
import '../../core/constants/supabase_constants.dart';
import 'dart:developer' as developer;
import '../services/content_localizer.dart';

class EditionRepository {
  final SupabaseClient _supabaseClient;

  EditionRepository(this._supabaseClient)
      : _localizer = ContentLocalizer.forClient(_supabaseClient);

  final ContentLocalizer _localizer;

  static const _editionFields = {'name': 'name', 'title': 'title', 'body': 'body'};
  static const _postFields = {'title': 'title', 'body': 'body'};

  Future<EditionModel> _localizeEdition(EditionModel edition, String language) async {
    if (!ContentLocalizer.needsTranslation(language)) return edition;
    final rows = await _localizer.localizeEntityRows(
      [
        {'id': edition.id, 'name': edition.name, 'title': edition.title, 'body': edition.body},
      ],
      language,
      entityType: 'edition',
      fields: _editionFields,
    );
    final row = rows.first;
    return edition.copyWith(
      name: row['name'] as String?,
      title: row['title'] as String?,
      body: row['body'] as String?,
    );
  }

  /// Get all editions with localization
  Future<List<EditionModel>> getAllEditionsLocalized(String language) async {
    final editions = await getAllEditions();
    if (!ContentLocalizer.needsTranslation(language)) return editions;
    final rows = await _localizer.localizeEntityRows(
      [
        for (final e in editions) {'id': e.id, 'name': e.name, 'title': e.title, 'body': e.body},
      ],
      language,
      entityType: 'edition',
      fields: _editionFields,
    );
    return [
      for (var i = 0; i < editions.length; i++)
        editions[i].copyWith(
          name: rows[i]['name'] as String?,
          title: rows[i]['title'] as String?,
          body: rows[i]['body'] as String?,
        ),
    ];
  }

  /// Get all editions with direct fields from editions table
  Future<List<EditionModel>> getAllEditions() async {
    try {
      developer.log('Fetching all editions...', name: 'EditionRepository');

      // Try without order first to see if that's the issue
      final response = await _supabaseClient
          .from(SupabaseConstants.editionsTable)
          .select('''
            id,
            name,
            title,
            body,
            image_url,
            pdf_url,
            published_at
          ''')
          .order('published_at', ascending: false);

      developer.log('Raw response type: ${response.runtimeType}', name: 'EditionRepository');

      final responseList = response as List;
      developer.log('Response length: ${responseList.length}', name: 'EditionRepository');

      if (responseList.isEmpty) {
        developer.log('WARNING: No editions found! This might be an RLS issue.', name: 'EditionRepository');
        return [];
      }

      developer.log('First edition: ${responseList[0]}', name: 'EditionRepository');

      final editions = responseList
          .map((json) => EditionModel.fromJson(json))
          .toList();

      // Sort in code
      editions.sort((a, b) {
        if (a.publishedAt == null && b.publishedAt == null) return 0;
        if (a.publishedAt == null) return 1;
        if (b.publishedAt == null) return -1;
        return b.publishedAt!.compareTo(a.publishedAt!);
      });

      developer.log('Returning ${editions.length} editions', name: 'EditionRepository');
      return editions;
    } catch (e, stackTrace) {
      developer.log('Error fetching editions: $e', name: 'EditionRepository', error: e, stackTrace: stackTrace);
      throw Exception('Failed to fetch editions: $e');
    }
  }

  /// Get edition by ID with localization
  Future<EditionModel?> getEditionByIdLocalized(String id, String language) async {
    final edition = await getEditionById(id);
    if (edition == null) return null;
    return _localizeEdition(edition, language);
  }

  /// Get edition by ID
  Future<EditionModel?> getEditionById(String id) async {
    try {
      final response = await _supabaseClient
          .from(SupabaseConstants.editionsTable)
          .select('''
            id,
            name,
            title,
            body,
            image_url,
            pdf_url,
            published_at
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return EditionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch edition: $e');
    }
  }

  /// Get recent editions with limit
  Future<List<EditionModel>> getRecentEditions({int limit = 10}) async {
    try {
      final response = await _supabaseClient
          .from(SupabaseConstants.editionsTable)
          .select('''
            id,
            name,
            title,
            body,
            image_url,
            pdf_url,
            published_at
          ''')
          .order('published_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => EditionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recent editions: $e');
    }
  }

  /// Get posts for a specific edition with category information
  Future<List<Map<String, dynamic>>> getEditionPosts(
    String editionId, {
    String language = ContentLocalizer.sourceLanguage,
  }) async {
    try {
      final response = await _supabaseClient
          .from(SupabaseConstants.postsTable)
          .select('''
            id,
            content_id,
            title,
            body,
            image_url,
            category_id,
            audio_id,
            created_at,
            categories!category_id(
              id,
              name
            )
          ''')
          .eq('edition_id', editionId)
          .order('created_at', ascending: true);

      final rows = (response as List)
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();
      await _localizer.localizeContentRows(rows, language, fields: _postFields);
      await _localizer.localizeNestedCategories(rows, language);
      return rows;
    } catch (e) {
      throw Exception('Failed to fetch edition posts: $e');
    }
  }

  /// Get audios for posts in an edition
  Future<List<Map<String, dynamic>>> getEditionAudios(
    String editionId, {
    String language = ContentLocalizer.sourceLanguage,
  }) async {
    try {
      // First get all posts with audio_id for this edition
      final posts = await _supabaseClient
          .from(SupabaseConstants.postsTable)
          .select('audio_id')
          .eq('edition_id', editionId)
          .not('audio_id', 'is', null);

      if (posts.isEmpty) return [];

      // Get the audio IDs
      final audioIds = (posts as List)
          .map((p) => p['audio_id']?.toString())
          .where((id) => id != null)
          .toList();

      if (audioIds.isEmpty) return [];

      // Fetch the audios
      final audios = await _supabaseClient
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
              edition_id
            )
          ''')
          .inFilter('id', audioIds);

      final rows = (audios as List)
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();

      // Translate the joined posts (title/body) of every audio.
      final joinedPosts = <Map<String, dynamic>>[];
      for (final row in rows) {
        final posts = row['posts'];
        if (posts is List) {
          for (final post in posts) {
            if (post is Map<String, dynamic>) joinedPosts.add(post);
          }
        } else if (posts is Map<String, dynamic>) {
          joinedPosts.add(posts);
        }
      }
      await _localizer.localizeContentRows(joinedPosts, language, fields: _postFields);
      await _localizer.localizeAudioUrls(rows, language);
      return rows;
    } catch (e) {
      throw Exception('Failed to fetch edition audios: $e');
    }
  }
}
