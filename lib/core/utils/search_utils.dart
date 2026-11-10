/// Full-text search helpers used by the in-app search.
///
/// * Case-, accent- and umlaut-insensitive ("Mädchen" = "maedchen",
///   "José" = "jose", "Ёлка" = "елка").
/// * Every word of the query must occur somewhere (any order); words in
///   "double quotes" must occur as an exact phrase.
/// * Hits in the title rank above hits in the text; whole-word and
///   word-start hits rank above hits in the middle of a word.
library;

/// A parsed search query.
class SearchQuery {
  SearchQuery._(this.raw, this.terms);

  /// Normalised terms (single words and quoted phrases).
  final List<String> terms;
  final String raw;

  bool get isEmpty => terms.isEmpty;

  factory SearchQuery.parse(String input) {
    final terms = <String>[];
    final phrase = RegExp(r'"([^"]+)"');
    var rest = input;
    for (final m in phrase.allMatches(input)) {
      final t = SearchText.normalize(m.group(1)!);
      if (t.isNotEmpty) terms.add(t);
    }
    rest = rest.replaceAll(phrase, ' ');
    for (final word in SearchText.normalize(rest).split(' ')) {
      if (word.isNotEmpty && !terms.contains(word)) terms.add(word);
    }
    return SearchQuery._(input, terms);
  }
}

/// Text prepared for searching (normalised once).
class SearchText {
  SearchText({required String title, String body = '', String extra = ''})
      : title = normalize(title),
        body = normalize(body),
        extra = normalize(extra),
        rawBody = _collapse(body);

  final String title;
  final String body;

  /// Additional searchable text (tags, edition name, reference …).
  final String extra;

  /// Original (not normalised) body, used for snippets.
  final String rawBody;

  static final _ws = RegExp(r'\s+');
  static final _nonWord = RegExp(r'''[^\p{L}\p{N}\s]''', unicode: true);

  static const Map<String, String> _fold = {
    'ä': 'ae', 'ö': 'oe', 'ü': 'ue', 'ß': 'ss',
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'å': 'a', 'ą': 'a',
    'ç': 'c', 'ć': 'c', 'č': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ę': 'e', 'ě': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ı': 'i',
    'ł': 'l', 'ñ': 'n', 'ń': 'n', 'ň': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ø': 'o',
    'ś': 's', 'š': 's', 'ş': 's', 'ș': 's',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ů': 'u',
    'ý': 'y', 'ÿ': 'y', 'ź': 'z', 'ż': 'z', 'ž': 'z',
    'ğ': 'g', 'ř': 'r', 'ť': 't', 'ď': 'd',
    'ё': 'е',
  };

  static String _collapse(String s) => s.replaceAll(_ws, ' ').trim();

  /// Lower case, umlauts/accents folded, punctuation removed, single spaces.
  static String normalize(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_fold[ch] ?? ch);
    }
    return _collapse(buffer.toString().replaceAll(_nonWord, ' '));
  }
}

/// Result of matching one item against a query.
class SearchMatch {
  const SearchMatch(this.score, this.snippet);

  final double score;

  /// Short excerpt of the body around the first hit (null for title-only).
  final String? snippet;
}

class SearchMatcher {
  SearchMatcher._();

  /// Returns null if [text] does not contain every term of [query].
  static SearchMatch? match(SearchQuery query, SearchText text) {
    if (query.isEmpty) return const SearchMatch(0, null);
    var score = 0.0;
    var bodyHit = false;
    for (final term in query.terms) {
      final inTitle = _termScore(text.title, term);
      final inExtra = _termScore(text.extra, term);
      final inBody = _termScore(text.body, term);
      if (inTitle == 0 && inExtra == 0 && inBody == 0) return null;
      score += inTitle * 10 + inExtra * 4 + inBody;
      if (inTitle == 0 && inBody > 0) bodyHit = true;
    }
    // Whole query as a phrase in the title: strong boost.
    final whole = query.terms.join(' ');
    if (query.terms.length > 1 && text.title.contains(whole)) score += 25;
    if (text.title == whole) score += 40;

    return SearchMatch(score, bodyHit ? snippet(text.rawBody, query) : null);
  }

  /// 0 = no hit; 1 = inside a word; 2 = word start; 3 = whole word.
  static double _termScore(String haystack, String term) {
    if (haystack.isEmpty) return 0;
    var index = haystack.indexOf(term);
    if (index < 0) return 0;
    var best = 1.0;
    var hits = 0;
    while (index >= 0 && hits < 20) {
      hits++;
      final startsWord = index == 0 || haystack.codeUnitAt(index - 1) == 32;
      final end = index + term.length;
      final endsWord = end == haystack.length || haystack.codeUnitAt(end) == 32;
      final s = startsWord ? (endsWord ? 3.0 : 2.0) : 1.0;
      if (s > best) best = s;
      index = haystack.indexOf(term, index + 1);
    }
    // More occurrences help a little (capped).
    return best + (hits > 1 ? (hits - 1).clamp(0, 5) * 0.2 : 0);
  }

  /// Excerpt of [raw] around the first occurrence of any query term.
  static String? snippet(String raw, SearchQuery query, {int radius = 60}) {
    if (raw.isEmpty) return null;
    final normalizedWords = <_Word>[];
    for (final m in RegExp(r'\S+').allMatches(raw)) {
      normalizedWords.add(_Word(m.start, m.end, SearchText.normalize(m.group(0)!)));
    }
    int? hitStart;
    for (final term in query.terms) {
      final first = term.split(' ').first;
      for (final w in normalizedWords) {
        if (w.normalized.contains(first)) {
          if (hitStart == null || w.start < hitStart) hitStart = w.start;
          break;
        }
      }
    }
    if (hitStart == null) return null;
    var from = (hitStart - radius).clamp(0, raw.length);
    var to = (hitStart + radius * 2).clamp(0, raw.length);
    // Snap to word boundaries.
    if (from > 0) {
      final space = raw.indexOf(' ', from);
      if (space >= 0 && space < hitStart) from = space + 1;
    }
    if (to < raw.length) {
      final space = raw.lastIndexOf(' ', to);
      if (space > hitStart) to = space;
    }
    final prefix = from > 0 ? '… ' : '';
    final suffix = to < raw.length ? ' …' : '';
    return '$prefix${raw.substring(from, to).trim()}$suffix';
  }

  /// Splits [text] into (segment, isHit) parts for highlighting.
  static List<(String, bool)> highlight(String text, SearchQuery query) {
    if (query.isEmpty || text.isEmpty) return [(text, false)];
    final words = query.terms.expand((t) => t.split(' ')).where((w) => w.length > 1).toSet();
    if (words.isEmpty) return [(text, false)];
    final parts = <(String, bool)>[];
    var last = 0;
    for (final m in RegExp(r'\S+').allMatches(text)) {
      final norm = SearchText.normalize(m.group(0)!);
      if (words.any(norm.contains)) {
        if (m.start > last) parts.add((text.substring(last, m.start), false));
        parts.add((m.group(0)!, true));
        last = m.end;
      }
    }
    if (last < text.length) parts.add((text.substring(last), false));
    return parts;
  }
}

class _Word {
  _Word(this.start, this.end, this.normalized);
  final int start;
  final int end;
  final String normalized;
}
