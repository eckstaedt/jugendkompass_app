import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/core/constants/supabase_constants.dart';
import 'dart:developer' as developer;

class AudioRepository {
  final SupabaseClient _supabase;

  AudioRepository(this._supabase);

  /// Get audio list with localized metadata from posts table
  Future<List<AudioModel>> getAudioListLocalized(String language, {
    String? categoryId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      developer.log('Fetching audio list for language: $language', name: 'AudioRepository');

      // For German, use regular method
      if (language == 'de') {
        return getAudioList(categoryId: categoryId, limit: limit, offset: offset);
      }

      // Get all audios first
      final audios = await getAudioList(categoryId: categoryId, limit: limit, offset: offset);

      // For each audio with a post, get the localized post data
      final localizedAudios = <AudioModel>[];
      for (final audio in audios) {
        if (audio.post?.contentId != null) {
          try {
            // Get localized post title and body using content_id
            final translatedPost = await _supabase.rpc(
              'tr',
              params: {
                'content_id': audio.post!.contentId,
                'lang': language,
                'field': 'title',
                'fallback': audio.post!.title,
              },
            );

            // Create a copy with translated title
            final updatedPost = audio.post!.copyWith(
              title: translatedPost ?? audio.post!.title,
            );

            localizedAudios.add(audio.copyWith(
              title: updatedPost.title,
            ));
          } catch (e) {
            developer.log('Error translating audio post: $e', name: 'AudioRepository');
            localizedAudios.add(audio);
          }
        } else {
          localizedAudios.add(audio);
        }
      }

      return localizedAudios;
    } catch (e) {
      developer.log('Error fetching localized audios: $e', name: 'AudioRepository', error: e);
      // Fallback to German on error
      return getAudioList(categoryId: categoryId, limit: limit, offset: offset);
    }
  }

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
              edition_id,
              categories(
                id,
                name
              )
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
              edition_id,
              categories(
                id,
                name
              )
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

  /// Get recommended audios based on category
  Future<List<AudioModel>> getRecommendedAudios({
    String? categoryId,
    String? excludeAudioId,
    int limit = 10,
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

      // Transform the response
      var audioList = (response as List).map((json) {
        final posts = json['posts'];
        Map<String, dynamic>? postData;
        if (posts is List && posts.isNotEmpty) {
          postData = posts[0] as Map<String, dynamic>;
          postData['audio_id'] = json['id'];
        }

        return AudioModel.fromJson({
          'id': json['id'],
          'url': json['url'],
          'post': postData,
        });
      }).toList();

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
