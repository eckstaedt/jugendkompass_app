import 'package:flutter/foundation.dart';

/// Parses jugendkompass.com URLs into content navigation data.
///
/// Supported URL patterns:
/// - https://jugendkompass.com/post/{id}
/// - https://jugendkompass.com/video/{id}
/// - https://jugendkompass.com/verse/{id}
/// - https://jugendkompass.com/message/{id}
/// - https://jugendkompass.com/impulse/{id}
/// - https://jugendkompass.com/poll/{id}
/// - https://jugendkompass.com/content/{id}
class UrlParserService {
  static final UrlParserService instance = UrlParserService._internal();
  UrlParserService._internal();

  static const String _httpsHost = 'jugendkompass.com';
  static const String _httpsWwwHost = 'www.jugendkompass.com';

  static const Map<String, String> _pathTypeMap = {
    'post': 'post',
    'artikel': 'post',
    'audio': 'post',
    'video': 'video',
    'impulse': 'impulse',
    'impuls': 'impulse',
    'message': 'message',
    'kurznachricht': 'message',
    'edition': 'edition',
    'ausgabe': 'edition',
    'poll': 'poll',
    'umfrage': 'poll',
    'verse': 'verse',
    'content': 'content',
    'bibelplan': 'bible_plan',
    'bible-plan': 'bible_plan',
    'reading-plan': 'bible_plan',
  };

  static const Map<String, String> _typeAliasMap = {
    'post_audio': 'post',
    'article': 'post',
    'articles': 'post',
    'videos': 'video',
    'messages': 'message',
    'impuls': 'impulse',
    'impulse': 'impulse',
    'editions': 'edition',
    'ausgabe': 'edition',
    'polls': 'poll',
    'umfrage': 'poll',
    'vers': 'verse',
    'verse_of_the_day': 'verse',
    'bibelplan': 'bible_plan',
    'reading_plan': 'bible_plan',
  };

  String _normalizeType(String rawType) {
    final type = rawType.trim().toLowerCase();
    return _typeAliasMap[type] ?? type;
  }

  String _normalizeContentId(String rawId) {
    var id = rawId.trim();
    try {
      id = Uri.decodeComponent(id);
    } catch (_) {}

    id = id.replaceAll(RegExp(r'^/+|/+$'), '');
    id = id.replaceAll(RegExp(r'[)\]>,.!?;:]+$'), '');
    return id;
  }

  /// Parse a jugendkompass.com URL into deep link data.
  ///
  /// Returns null if URL is not recognized or invalid.
  /// Returns Map with 'contentType' and 'contentId' keys on success.
  Map<String, String>? parseUrl(String urlString) {
    try {
      final uri = Uri.parse(urlString);

      // Support custom scheme fallback: jugendkompass://post/{id}
      if (uri.scheme == 'jugendkompass') {
        final hostType = uri.host.trim().toLowerCase();
        final normalizedFromHost = _pathTypeMap[hostType];

        if (normalizedFromHost == 'bible_plan') {
          return {'contentType': 'bible_plan'};
        }

        final idFromPath = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        if (normalizedFromHost != null && idFromPath != null && idFromPath.isNotEmpty) {
          return {
            'contentType': normalizedFromHost,
            'contentId': idFromPath,
          };
        }

        final queryType = uri.queryParameters['type'] ?? uri.queryParameters['contentType'];
        final queryId = uri.queryParameters['id'] ?? uri.queryParameters['contentId'];
        if (queryType != null && queryType.isNotEmpty) {
          final normalized = _normalizeType(queryType);
          if (normalized == 'bible_plan') {
            return {'contentType': 'bible_plan'};
          }
          if (queryId != null && queryId.isNotEmpty) {
            final normalizedId = _normalizeContentId(queryId);
            if (normalizedId.isEmpty) return null;
            return {
              'contentType': normalized,
              'contentId': normalizedId,
            };
          }
        }

        debugPrint('[UrlParser] Invalid jugendkompass:// URL: $uri');
        return null;
      }

      // Only handle jugendkompass.com URLs for HTTPS links
      if (uri.host != _httpsHost && uri.host != _httpsWwwHost) {
        debugPrint('[UrlParser] Not a jugendkompass.com URL: ${uri.host}');
        return null;
      }

      // Optional query-style links:
      // https://jugendkompass.com/open?type=post&id=uuid
      final queryType = uri.queryParameters['type'] ?? uri.queryParameters['contentType'];
      final queryId = uri.queryParameters['id'] ?? uri.queryParameters['contentId'];
      if (queryType != null && queryType.isNotEmpty) {
        final normalized = _normalizeType(queryType);
        if (normalized == 'bible_plan') {
          return {'contentType': 'bible_plan'};
        }
        if (queryId != null && queryId.isNotEmpty) {
          final normalizedId = _normalizeContentId(queryId);
          if (normalizedId.isEmpty) return null;
          return {
            'contentType': normalized,
            'contentId': normalizedId,
          };
        }
      }

      // Extract path segments
      final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
      if (segments.isEmpty || segments.length > 3) {
        debugPrint('[UrlParser] Invalid path structure: ${uri.path}');
        return null;
      }

      // Handle root path or single segment differently
      if (segments.length == 1) {
        final onlySegment = segments.first.toLowerCase();
        final maybeType = _pathTypeMap[onlySegment];

        // Allow direct plan links without ID
        if (maybeType == 'bible_plan') {
          return {'contentType': 'bible_plan'};
        }

        // Could be tab navigation like /videos, /podcasts etc.
        debugPrint('[UrlParser] Single segment path (non-content route): ${uri.path}');
        return null;
      }

      // Supported path forms:
      // - /post/{id}
      // - /share/post/{id}
      final isSharePrefix = segments.first.toLowerCase() == 'share';
      final typeSegment = isSharePrefix ? segments[1].toLowerCase() : segments[0].toLowerCase();
      final rawIdSegment = isSharePrefix ? (segments.length >= 3 ? segments[2] : '') : segments[1];
      final idSegment = _normalizeContentId(rawIdSegment);

      final normalizedType = _pathTypeMap[typeSegment] ?? _normalizeType(typeSegment);
      if (normalizedType != 'bible_plan' && idSegment.isEmpty) {
        debugPrint('[UrlParser] Missing content id for type: $normalizedType');
        return null;
      }

      const validTypes = {
        'post',
        'video',
        'verse',
        'message',
        'impulse',
        'poll',
        'content',
        'edition',
        'bible_plan',
      };

      if (!validTypes.contains(normalizedType)) {
        debugPrint('[UrlParser] Unknown content type: $normalizedType');
        return null;
      }

      if (normalizedType == 'bible_plan') {
        debugPrint('[UrlParser] Parsed URL: type=bible_plan');
        return {'contentType': 'bible_plan'};
      }

      debugPrint('[UrlParser] Parsed URL: type=$normalizedType, id=$idSegment');
      return {
        'contentType': normalizedType,
        'contentId': idSegment,
      };
    } catch (e) {
      debugPrint('[UrlParser] Error parsing URL: $e');
      return null;
    }
  }
}
