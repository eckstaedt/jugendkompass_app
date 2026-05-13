import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_model.dart';
import 'dart:developer' as developer;

class VideoRepository {
  final SupabaseClient _supabase;

  VideoRepository(this._supabase);

  /// Fetch all videos with localization
  Future<List<VideoModel>> getVideoListLocalized(String language, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      developer.log('Fetching videos for language: $language', name: 'VideoRepository');

      // For German, use regular method
      if (language == 'de') {
        return getVideoList(limit: limit, offset: offset);
      }

      // Use RPC function to get localized videos
      final response = await _supabase.rpc(
        'get_videos_localized',
        params: {'lang': language},
      );

      if (response == null || (response is List && response.isEmpty)) {
        // Fallback to German if no translations
        return getVideoList(limit: limit, offset: offset);
      }

      final videoList = (response as List)
          .map((json) => VideoModel.fromJson(json))
          .toList();

      // Apply pagination in code
      final startIndex = offset.clamp(0, videoList.length);
      final endIndex = (offset + limit).clamp(0, videoList.length);

      return videoList.sublist(startIndex, endIndex);
    } catch (e) {
      developer.log('Error fetching localized videos: $e', name: 'VideoRepository', error: e);
      // Fallback to German on error
      return getVideoList(limit: limit, offset: offset);
    }
  }

  /// Fetch all videos
  Future<List<VideoModel>> getVideoList({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => VideoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch videos: $e');
    }
  }

  /// Fetch a single video by ID with localization
  Future<VideoModel?> getVideoByIdLocalized(String id, String language) async {
    try {
      // For German, use regular method
      if (language == 'de') {
        return getVideoById(id);
      }

      // Use RPC function to get localized video
      final response = await _supabase.rpc(
        'get_video_by_id_localized',
        params: {'video_id': id, 'lang': language},
      );

      if (response == null) {
        // Fallback to German if no translation
        return getVideoById(id);
      }

      return VideoModel.fromJson(response);
    } catch (e) {
      developer.log('Error fetching localized video: $e', name: 'VideoRepository', error: e);
      // Fallback to German on error
      return getVideoById(id);
    }
  }

  /// Fetch a single video by ID
  Future<VideoModel?> getVideoById(String id) async {
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return VideoModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch video: $e');
    }
  }

  /// Fetch video by content ID
  Future<VideoModel?> getVideoByContentId(String contentId) async {
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .eq('content_id', contentId)
          .maybeSingle();

      if (response == null) return null;

      return VideoModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch video by content ID: $e');
    }
  }
}
