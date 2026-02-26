import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/edition_model.dart';
import '../../core/constants/supabase_constants.dart';
import 'dart:developer' as developer;

class EditionRepository {
  final SupabaseClient _supabaseClient;

  EditionRepository(this._supabaseClient);

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
          ''');

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
  Future<List<Map<String, dynamic>>> getEditionPosts(String editionId) async {
    try {
      final response = await _supabaseClient
          .from(SupabaseConstants.postsTable)
          .select('''
            id,
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

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch edition posts: $e');
    }
  }

  /// Get audios for posts in an edition
  Future<List<Map<String, dynamic>>> getEditionAudios(String editionId) async {
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

      return (audios as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch edition audios: $e');
    }
  }
}
