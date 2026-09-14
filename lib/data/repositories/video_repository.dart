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

  /// Resolve a video from either video.id or video.content_id.
  ///
  /// This is used by deep links/shared links where the identifier may vary.
  Future<VideoModel?> getVideoByAnyId(String identifier, String language) async {
    try {
      final candidates = _buildIdentifierCandidates(identifier);
      if (candidates.isEmpty) return null;

      VideoModel? video;
      for (final candidate in candidates) {
        video = await getVideoByIdLocalized(candidate, language);
        video ??= await getVideoByContentId(candidate);
        video ??= await getVideoById(candidate);
        if (video != null) return video;
      }

      final normalizedCandidateSet = candidates.map(_normalizeLoose).toSet();

      String? youtubeIdCandidate;
      for (final candidate in candidates) {
        final maybeId = _extractYoutubeId(candidate);
        if (maybeId != null && maybeId.isNotEmpty) {
          youtubeIdCandidate = maybeId;
          normalizedCandidateSet.add(_normalizeLoose(maybeId));
          break;
        }
      }

      // Try fast exact URL matching before expensive list scans.
      for (final candidate in candidates) {
        final fromExactUrl = await _getVideoByExactUrl(candidate);
        if (fromExactUrl != null) return fromExactUrl;
      }

      if (youtubeIdCandidate != null) {
        final fromYoutubeScan = await _getVideoByYoutubeIdScan(youtubeIdCandidate);
        if (fromYoutubeScan != null) return fromYoutubeScan;
      }

      final allLocalized = await getVideoListLocalized(language, limit: 500);
      for (final item in allLocalized) {
        final itemKeys = {
          _normalizeLoose(item.id),
          _normalizeLoose(item.contentId),
          _normalizeLoose(item.videoUrl),
        };
        final itemYoutube = _extractYoutubeId(item.videoUrl);
        if (itemYoutube != null) {
          itemKeys.add(_normalizeLoose(itemYoutube));
        }

        if (itemKeys.any(normalizedCandidateSet.contains)) {
          return item;
        }
      }

      final allDefault = await getVideoList(limit: 500);
      for (final item in allDefault) {
        final itemKeys = {
          _normalizeLoose(item.id),
          _normalizeLoose(item.contentId),
          _normalizeLoose(item.videoUrl),
        };
        final itemYoutube = _extractYoutubeId(item.videoUrl);
        if (itemYoutube != null) {
          itemKeys.add(_normalizeLoose(itemYoutube));
        }

        if (itemKeys.any(normalizedCandidateSet.contains)) {
          return item;
        }
      }

      return null;
    } catch (e) {
      developer.log(
        'Error resolving video by any id: $e',
        name: 'VideoRepository',
        error: e,
      );
      return null;
    }
  }

  Future<VideoModel?> _getVideoByExactUrl(String url) async {
    try {
      if (url.trim().isEmpty || !url.contains('http')) return null;
      final response = await _supabase
          .from('videos')
          .select()
          .eq('url', url)
          .maybeSingle();

      if (response == null) return null;
      return VideoModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<VideoModel?> _getVideoByYoutubeIdScan(String youtubeId) async {
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .ilike('url', '%$youtubeId%')
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return VideoModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Set<String> _buildIdentifierCandidates(String raw) {
    final candidates = <String>{};
    final base = raw.trim();
    if (base.isEmpty) return candidates;

    candidates.add(base);
    candidates.add(base.replaceAll(RegExp(r'/$'), ''));

    try {
      candidates.add(Uri.decodeComponent(base));
    } catch (_) {}

    try {
      candidates.add(Uri.decodeFull(base));
    } catch (_) {}

    final youtubeId = _extractYoutubeId(base);
    if (youtubeId != null && youtubeId.isNotEmpty) {
      candidates.add(youtubeId);
    }

    candidates.removeWhere((value) => value.trim().isEmpty);
    return candidates;
  }

  String _normalizeLoose(String value) {
    var normalized = value.trim().toLowerCase();
    try {
      normalized = Uri.decodeComponent(normalized);
    } catch (_) {}
    normalized = normalized.replaceAll(RegExp(r'^/+|/+$'), '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), '');
    return normalized;
  }

  String? _extractYoutubeId(String input) {
    final value = input.trim();
    if (value.isEmpty) return null;

    final idOnlyPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');
    if (idOnlyPattern.hasMatch(value)) {
      return value;
    }

    Uri? uri;
    try {
      uri = Uri.parse(value);
    } catch (_) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
      return null;
    }

    if (host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) {
        return v;
      }
      final segments = uri.pathSegments;
      final shortsIndex = segments.indexOf('shorts');
      if (shortsIndex != -1 && segments.length > shortsIndex + 1) {
        return segments[shortsIndex + 1];
      }
      final embedIndex = segments.indexOf('embed');
      if (embedIndex != -1 && segments.length > embedIndex + 1) {
        return segments[embedIndex + 1];
      }
    }

    return null;
  }
}
