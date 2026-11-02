import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_model.dart';
import 'dart:developer' as developer;
import '../services/content_localizer.dart';

class VideoRepository {
  final SupabaseClient _supabase;

  VideoRepository(this._supabase) : _localizer = ContentLocalizer.forClient(_supabase);

  final ContentLocalizer _localizer;

  static const _fields = {'title': 'title', 'description': 'description'};

  /// Applies translations to an already loaded video.
  Future<VideoModel> localizeVideo(VideoModel video, String language) async {
    if (!ContentLocalizer.needsTranslation(language) || video.contentId.isEmpty) return video;
    final values = await _localizer.translationsForContent(video.contentId, language);
    final title = values['title'];
    final description = values['description'];
    return video.copyWith(
      title: (title != null && title.trim().isNotEmpty) ? title : null,
      description: (description != null && description.trim().isNotEmpty) ? description : null,
    );
  }

  /// Fetch all videos with localization (German rows + translation overlay)
  Future<List<VideoModel>> getVideoListLocalized(String language, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('videos')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final rows = (response as List).map((json) => Map<String, dynamic>.from(json as Map)).toList();
      await _localizer.localizeContentRows(rows, language, fields: _fields);
      return rows.map(VideoModel.fromJson).toList();
    } catch (e) {
      developer.log('Error fetching localized videos: $e', name: 'VideoRepository', error: e);
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
      final video = await getVideoById(id);
      if (video == null) return null;
      return localizeVideo(video, language);
    } catch (e) {
      developer.log('Error fetching localized video: $e', name: 'VideoRepository', error: e);
      return null;
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
        video ??= await _safe(() => getVideoByContentId(candidate));
        if (video != null) return localizeVideo(video, language);
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
        if (fromExactUrl != null) return localizeVideo(fromExactUrl, language);
      }

      if (youtubeIdCandidate != null) {
        final fromYoutubeScan = await _getVideoByYoutubeIdScan(youtubeIdCandidate);
        if (fromYoutubeScan != null) return localizeVideo(fromYoutubeScan, language);
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
          return localizeVideo(item, language);
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

  Future<VideoModel?> _safe(Future<VideoModel?> Function() load) async {
    try {
      return await load();
    } catch (_) {
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
