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

  /// Parse a jugendkompass.com URL into deep link data.
  ///
  /// Returns null if URL is not recognized or invalid.
  /// Returns Map with 'contentType' and 'contentId' keys on success.
  Map<String, String>? parseUrl(String urlString) {
    try {
      final uri = Uri.parse(urlString);

      // Only handle jugendkompass.com URLs
      if (uri.host != 'jugendkompass.com' && uri.host != 'www.jugendkompass.com') {
        debugPrint('[UrlParser] Not a jugendkompass.com URL: ${uri.host}');
        return null;
      }

      // Extract path segments
      final segments = uri.pathSegments;
      if (segments.isEmpty || segments.length > 2) {
        debugPrint('[UrlParser] Invalid path structure: ${uri.path}');
        return null;
      }

      // Handle root path or single segment differently
      if (segments.length == 1) {
        // Could be a tab navigation like /videos, /podcasts, etc.
        // Return null to let browser/web handle it
        debugPrint('[UrlParser] Single segment path (tab navigation): ${uri.path}');
        return null;
      }

      final contentType = segments[0]; // 'post', 'video', etc.
      final contentId = segments[1];   // UUID

      // Validate content type
      const validTypes = ['post', 'video', 'verse', 'message', 'impulse', 'poll', 'content'];
      if (!validTypes.contains(contentType)) {
        debugPrint('[UrlParser] Unknown content type: $contentType');
        return null;
      }

      debugPrint('[UrlParser] Parsed URL: type=$contentType, id=$contentId');
      return {
        'contentType': contentType,
        'contentId': contentId,
      };
    } catch (e) {
      debugPrint('[UrlParser] Error parsing URL: $e');
      return null;
    }
  }
}
