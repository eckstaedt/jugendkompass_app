import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';

class AudioRepository {
  final SupabaseClient _supabase;

  AudioRepository(this._supabase);

  /// Get audio list with metadata from posts table
  /// Joins audios with posts where posts.audio_id = audios.id
  Future<List<AudioModel>> getAudioList({
    String? categoryId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Join audios with posts to get full post data
      final query = _supabase
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
          .range(offset, offset + limit - 1);

      final response = await query;

      // Transform the response to include full post in AudioModel
      return (response as List).map((json) {
        // Extract posts data if available
        final posts = json['posts'];
        Map<String, dynamic>? postData;
        if (posts is List && posts.isNotEmpty) {
          postData = posts[0] as Map<String, dynamic>;
          // Add audio_id to post data
          postData['audio_id'] = json['id'];
        }

        return AudioModel.fromJson({
          'id': json['id'],
          'url': json['url'],
          'post': postData,
        });
      }).toList();
    } catch (e) {
      throw Exception('Fehler beim Laden der Audios: $e');
    }
  }

  /// Get audio by ID with metadata from posts table
  Future<AudioModel?> getAudioById(String id) async {
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
              edition_id
            )
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        // Extract posts data if available
        final posts = response['posts'];
        Map<String, dynamic>? postData;
        if (posts is List && posts.isNotEmpty) {
          postData = posts[0] as Map<String, dynamic>;
          // Add audio_id to post data
          postData['audio_id'] = response['id'];
        }

        return AudioModel.fromJson({
          'id': response['id'],
          'url': response['url'],
          'post': postData,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Fehler beim Laden des Audios: $e');
    }
  }
}
