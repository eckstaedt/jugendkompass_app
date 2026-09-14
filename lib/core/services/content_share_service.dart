import 'package:share_plus/share_plus.dart';

/// Central service for generating and sharing Jugendkompass deep links.
///
/// Canonical shared URL format:
/// - https://jugendkompass.com/open?type={type}&id={id}
///
/// Supported types include: post, video, impulse, message, edition, poll,
/// verse, content.
class ContentShareService {
  ContentShareService._();

  static const String _baseUrl = 'https://jugendkompass.com';

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
    final uri = Uri.parse('$_baseUrl/open').replace(queryParameters: {
      'type': typePath,
      'id': contentId,
    });
    return uri.toString();
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
