import 'package:share_plus/share_plus.dart';

/// Central service for generating and sharing Jugendkompass deep links.
///
/// Canonical shared URL format:
/// - https://www.jugendkompass.com/{type}/{id}
///
/// The `www.` host is deliberate: it is the host that serves
/// `apple-app-site-association` / `assetlinks.json` directly (the bare
/// domain only redirects there, and iOS/Android do not follow redirects when
/// verifying Universal Links / App Links). Links on this host therefore open
/// the app directly when it is installed, without a detour via the browser.
///
/// The website renders the same URL server-side with Open Graph tags (title,
/// description, cover image), so messengers show a preview card with the
/// content's cover image (see `web/api/share.js`).
///
/// Supported types: post, video, impulse, message, edition, poll, verse,
/// content.
class ContentShareService {
  ContentShareService._();

  static const String _baseUrl = 'https://www.jugendkompass.com';

  static const Map<String, String> _typePathMap = {
    'post': 'post',
    'video': 'video',
    'impulse': 'impulse',
    'message': 'message',
    'edition': 'edition',
    'poll': 'poll',
    'verse': 'verse',
    'content': 'content',
    'post_audio': 'post',
    'podcast': 'post',
    'audio': 'post',
    'article': 'post',
    'ausgabe': 'edition',
  };

  static String _normalizeType(String contentType) {
    final type = contentType.trim().toLowerCase();
    return _typePathMap[type] ?? type;
  }

  static String buildContentUrl({
    required String contentType,
    required String contentId,
  }) {
    final typePath = _normalizeType(contentType);
    return Uri.parse(_baseUrl)
        .replace(pathSegments: [typePath, contentId.trim()])
        .toString();
  }

  static Future<void> shareContent({
    required String contentType,
    required String contentId,
    required String title,
    String? intro,
  }) async {
    final url = buildContentUrl(
      contentType: contentType,
      contentId: contentId,
    );

    final introLine = (intro != null && intro.trim().isNotEmpty)
        ? '${intro.trim()}\n\n'
        : '';

    final text = '$introLine$title\n$url';
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: title,
      ),
    );
  }
}
