import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/post_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';

class PostRepository {
  final SupabaseClient _supabase;

  PostRepository(this._supabase);

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
          .order('id', ascending: false)
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

  /// Get localized posts using Supabase RPC function.
  ///
  /// This uses the get_posts_localized(lang) function which returns posts
  /// with translated title and body fields based on content_translations table.
  /// German (de) returns the original content from posts table.
  Future<List<PostModel>> getPostsLocalized(
    String language, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_posts_localized',
        params: {'lang': language},
      );

      final posts = (response as List)
          .map((json) => PostModel.fromJson(json))
          .toList();

      // Apply limit and offset client-side
      // (RPC function returns all posts, we paginate here)
      return posts.skip(offset).take(limit).toList();
    } catch (e) {
      // Fallback to regular posts if RPC fails
      throw Exception('Fehler beim Laden der lokalisierten Posts: $e');
    }
  }

  /// Get a single localized post by ID.
  ///
  /// Falls back to German content if translation not available.
  Future<PostModel?> getPostByIdLocalized(String id, String language) async {
    try {
      // For German, just use regular method
      if (language == 'de') {
        return getPostById(id);
      }

      // Get post with translations
      final post = await getPostById(id);
      if (post == null) return null;

      // If no content_id, return as-is
      if (post.contentId == null) return post;

      // Fetch translations for this content
      final translations = await _supabase
          .from('content_translations')
          .select('field_name, value')
          .eq('content_id', post.contentId!)
          .eq('language', language);

      // Apply translations
      String? translatedTitle;
      String? translatedBody;

      for (final row in translations as List) {
        final field = row['field_name'] as String;
        final value = row['value'] as String;

        if (field == 'title') translatedTitle = value;
        if (field == 'body') translatedBody = value;
      }

      // Return post with translations (fallback to German if not found)
      return PostModel(
        id: post.id,
        title: translatedTitle ?? post.title,
        body: translatedBody ?? post.body,
        imageUrl: post.imageUrl,
        categoryId: post.categoryId,
        editionId: post.editionId,
        audioId: post.audioId,
        contentId: post.contentId,
      );
    } catch (e) {
      throw Exception('Fehler beim Laden des lokalisierten Posts: $e');
    }
  }
}
