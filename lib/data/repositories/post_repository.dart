import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/post_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';
import 'package:jugendkompass_app/data/services/content_localizer.dart';

class PostRepository {
  final SupabaseClient _supabase;

  PostRepository(this._supabase) : _localizer = ContentLocalizer.forClient(_supabase);

  final ContentLocalizer _localizer;

  /// Get all posts with optional filters
  Future<List<PostModel>> getPostList({
    String? categoryId,
    String? editionId,
    String? contentId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      dynamic query = _supabase
          .from(SupabaseConstants.postsTable)
          .select();

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (editionId != null) {
        query = query.eq('edition_id', editionId);
      }

      if (contentId != null) {
        query = query.eq('content_id', contentId);
      }

      query = query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;

      return (response as List)
          .map((json) => PostModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Fehler beim Laden der Posts: $e');
    }
  }

  /// Get a single post by ID
  Future<PostModel?> getPostById(String id) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.postsTable)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return PostModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Fehler beim Laden des Posts: $e');
    }
  }

  /// Get a single post by its content_id (FK to the polymorphic `content` table).
  /// Used for deep linking from push notifications, which sometimes reference
  /// the content_id rather than the post's own id.
  Future<PostModel?> getPostByContentId(String contentId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.postsTable)
          .select()
          .eq('content_id', contentId)
          .maybeSingle();

      if (response != null) {
        return PostModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Fehler beim Laden des Posts: $e');
    }
  }

  /// Get a localized post by content_id.
  Future<PostModel?> getPostByContentIdLocalized(String contentId, String language) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.postsTable)
          .select()
          .eq('content_id', contentId)
          .maybeSingle();
      if (response == null) return null;
      final rows = await _localize([Map<String, dynamic>.from(response)], language);
      return PostModel.fromJson(rows.first);
    } catch (e) {
      throw Exception('Fehler beim Laden des lokalisierten Posts: $e');
    }
  }

  /// Get posts by edition ID
  Future<List<PostModel>> getPostsByEdition(String editionId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.postsTable)
          .select()
          .eq('edition_id', editionId)
          .order('id', ascending: false);

      return (response as List)
          .map((json) => PostModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Fehler beim Laden der Posts: $e');
    }
  }

  /// Get posts by audio ID
  Future<PostModel?> getPostByAudioId(String audioId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.postsTable)
          .select()
          .eq('audio_id', audioId)
          .maybeSingle();

      if (response != null) {
        return PostModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Fehler beim Laden des Posts: $e');
    }
  }

  /// Get localized posts.
  ///
  /// Always loads the German source rows (same shape for every language,
  /// including the categories join) and overlays the translations.
  Future<List<PostModel>> getPostsLocalized(
    String language, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_posts_localized',
        params: {'lang': ContentLocalizer.sourceLanguage},
      );

      final rows = (response as List)
          .map((json) => Map<String, dynamic>.from(json as Map))
          .skip(offset)
          .take(limit)
          .toList();

      final localized = await _localize(rows, language);
      return localized.map(PostModel.fromJson).toList();
    } catch (e) {
      throw Exception('Fehler beim Laden der lokalisierten Posts: $e');
    }
  }

  /// Get a single localized post by ID (falls back to German per field).
  Future<PostModel?> getPostByIdLocalized(String id, String language) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.postsTable)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      final rows = await _localize([Map<String, dynamic>.from(response)], language);
      return PostModel.fromJson(rows.first);
    } catch (e) {
      throw Exception('Fehler beim Laden des lokalisierten Posts: $e');
    }
  }

  /// Localized posts of an edition.
  Future<List<PostModel>> getPostsByEditionLocalized(String editionId, String language) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.postsTable)
          .select()
          .eq('edition_id', editionId)
          .order('id', ascending: false);
      final rows = (response as List).map((json) => Map<String, dynamic>.from(json as Map)).toList();
      final localized = await _localize(rows, language);
      return localized.map(PostModel.fromJson).toList();
    } catch (e) {
      throw Exception('Fehler beim Laden der Posts: $e');
    }
  }

  /// Localized post for an audio.
  Future<PostModel?> getPostByAudioIdLocalized(String audioId, String language) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.postsTable)
          .select()
          .eq('audio_id', audioId)
          .maybeSingle();
      if (response == null) return null;
      final rows = await _localize([Map<String, dynamic>.from(response)], language);
      return PostModel.fromJson(rows.first);
    } catch (e) {
      throw Exception('Fehler beim Laden des Posts: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _localize(
    List<Map<String, dynamic>> rows,
    String language,
  ) async {
    if (!ContentLocalizer.needsTranslation(language)) return rows;

    // RPC rows may come without content_id → resolve it from the posts table.
    final missingIds = rows
        .where((row) => row['content_id'] == null && row['id'] != null)
        .map((row) => row['id'].toString())
        .toList();
    if (missingIds.isNotEmpty) {
      try {
        final mapping = await _supabase
            .from(SupabaseConstants.postsTable)
            .select('id, content_id')
            .inFilter('id', missingIds);
        final byId = {
          for (final m in mapping as List) m['id'].toString(): m['content_id'],
        };
        for (final row in rows) {
          row['content_id'] ??= byId[row['id']?.toString()];
        }
      } catch (_) {
        // keep German on failure
      }
    }

    await _localizer.localizeContentRows(
      rows,
      language,
      fields: const {'title': 'title', 'body': 'body'},
    );
    await _localizer.localizeNestedCategories(rows, language);
    return rows;
  }
}
