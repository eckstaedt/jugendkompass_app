import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'dart:developer' as developer;

/// Service that translates German database content to the selected app language.
///
/// Uses the MyMemory free translation API (no API key required,
/// 1 000 requests / day on the free tier).
/// Results are cached in SharedPreferences so the same string is never
/// translated twice (even across restarts).
class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  // In-memory cache:  cacheKey → translated string
  final Map<String, String> _memoryCache = {};

  static const String _prefPrefix = 'translation_cache_';

  // Maps AppLanguage to the ISO 639-1 code expected by MyMemory
  static const Map<AppLanguage, String> _langCodes = {
    AppLanguage.de: 'de',
    AppLanguage.en: 'en',
    AppLanguage.ru: 'ru',
    AppLanguage.pl: 'pl',
    AppLanguage.tr: 'tr',
  };

  /// Translate [text] from German to [targetLanguage].
  ///
  /// Returns the original [text] immediately if:
  ///  - [text] is null / empty
  ///  - [targetLanguage] is German (nothing to translate)
  ///
  /// Otherwise calls MyMemory with caching.
  Future<String> translate(String? text, AppLanguage targetLanguage) async {
    if (text == null || text.trim().isEmpty) return text ?? '';
    if (targetLanguage == AppLanguage.de) return text;

    final targetCode = _langCodes[targetLanguage] ?? 'en';
    final cacheKey = '${targetCode}_${_hashText(text)}';

    // 1. In-memory cache hit
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // 2. Persistent cache hit
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_prefPrefix$cacheKey');
      if (cached != null) {
        _memoryCache[cacheKey] = cached;
        return cached;
      }
    } catch (_) {}

    // 3. Network call
    try {
      final translated = await _callMyMemory(text, targetCode);
      if (translated.isNotEmpty) {
        _memoryCache[cacheKey] = translated;
        _persistToCache(cacheKey, translated); // fire-and-forget
        return translated;
      }
    } catch (e) {
      developer.log(
        'TranslationService: failed to translate – $e',
        name: 'TranslationService',
      );
    }

    // Fallback: return original German text
    return text;
  }

  /// Translate a list of strings in a single batch call.
  /// Joins them with a unique separator, translates, then splits again.
  Future<List<String>> translateBatch(
    List<String> texts,
    AppLanguage targetLanguage,
  ) async {
    if (targetLanguage == AppLanguage.de) return texts;
    if (texts.isEmpty) return texts;

    // Translate each individually (MyMemory doesn't support batches well)
    final results = <String>[];
    for (final t in texts) {
      results.add(await translate(t, targetLanguage));
    }
    return results;
  }

  // ───────────── Private helpers ─────────────

  Future<String> _callMyMemory(String text, String targetCode) async {
    // MyMemory accepts up to ~500 characters per request reliably.
    // For longer texts (e.g. article body HTML) we chunk at paragraph level.
    if (text.length <= 500) {
      return await _singleRequest(text, targetCode);
    }
    return await _translateLongText(text, targetCode);
  }

  Future<String> _singleRequest(String text, String targetCode) async {
    final uri = Uri.https('api.mymemory.translated.net', '/get', {
      'q': text,
      'langpair': 'de|$targetCode',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('MyMemory HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final responseData = body['responseData'] as Map<String, dynamic>?;
    final translatedText = responseData?['translatedText'] as String?;

    if (translatedText == null || translatedText.isEmpty) {
      throw Exception('MyMemory returned empty translation');
    }

    // MyMemory sometimes returns "PLEASE SELECT TWO DISTINCT LANGUAGES" etc.
    if (translatedText.startsWith('PLEASE ') ||
        translatedText.contains('MYMEMORY WARNING')) {
      throw Exception('MyMemory quota exceeded or error: $translatedText');
    }

    return translatedText;
  }

  /// For texts > 500 chars we split on paragraph boundaries and translate
  /// each chunk, then reassemble.
  Future<String> _translateLongText(String text, String targetCode) async {
    // Split on blank lines (paragraphs) or <p> / <br> tags if HTML
    final parts = _splitIntoParts(text);
    final translatedParts = <String>[];

    for (final part in parts) {
      if (part.trim().isEmpty) {
        translatedParts.add(part);
        continue;
      }
      if (part.length <= 500) {
        translatedParts.add(await _singleRequest(part, targetCode));
      } else {
        // Hard split on 500-char boundaries, preferring word boundaries
        final subParts = _hardSplit(part, 500);
        final translatedSubParts = <String>[];
        for (final sub in subParts) {
          translatedSubParts.add(await _singleRequest(sub, targetCode));
        }
        translatedParts.add(translatedSubParts.join(' '));
      }
    }

    return translatedParts.join('\n');
  }

  List<String> _splitIntoParts(String text) {
    // Split on blank lines (plain text paragraphs)
    return text.split(RegExp(r'\n{2,}'));
  }

  List<String> _hardSplit(String text, int maxLen) {
    final parts = <String>[];
    var start = 0;
    while (start < text.length) {
      var end = (start + maxLen).clamp(0, text.length);
      // Try to break on a space
      if (end < text.length) {
        final spaceIdx = text.lastIndexOf(' ', end);
        if (spaceIdx > start) end = spaceIdx;
      }
      parts.add(text.substring(start, end).trim());
      start = end;
    }
    return parts;
  }

  /// Simple stable hash of a string to use as a compact cache key.
  String _hashText(String text) {
    // Use first 60 chars + length as a lightweight fingerprint
    final prefix = text.length > 60 ? text.substring(0, 60) : text;
    return '${prefix.hashCode.abs()}_${text.length}';
  }

  Future<void> _persistToCache(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefPrefix$key', value);
    } catch (_) {}
  }

  /// Clears all cached translations (e.g. when language is reset).
  Future<void> clearCache() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefPrefix));
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}
