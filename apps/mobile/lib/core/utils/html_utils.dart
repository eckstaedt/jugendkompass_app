/// Utility class for handling HTML text throughout the app.
class HtmlUtils {
  HtmlUtils._();

  /// Strip all HTML tags and decode common HTML entities from a string.
  /// Returns clean plain text suitable for display in [Text] widgets.
  static String stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&ndash;', '–')
        .replaceAll('&mdash;', '—')
        .replaceAll('&hellip;', '…')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// Strip HTML and truncate to a maximum length with ellipsis.
  static String stripAndTruncate(String html, {int maxLength = 100}) {
    final text = stripHtml(html);
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }
}
