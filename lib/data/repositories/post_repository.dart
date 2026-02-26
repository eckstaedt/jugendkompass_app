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
}
