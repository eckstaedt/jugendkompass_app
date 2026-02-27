import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_model.dart';

class VideoRepository {
  final SupabaseClient _supabase;

  VideoRepository(this._supabase);

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
