import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Swaps cover image URLs for versions whose text was translated by AI
/// (table `image_translations`, filled by tool/image_translate).
///
/// The mapping (original URL → translated URL) for the current language is
/// small, so it is loaded once per language, kept in memory and cached on
/// disk (no flicker on cold start). Unknown URLs and German stay unchanged.
class ImageLocalizer {
  ImageLocalizer._();
  static final ImageLocalizer instance = ImageLocalizer._();

  /// Rebuilds image widgets when the mapping changes.
  final ValueNotifier<Map<String, String>> map = ValueNotifier(const {});

  String _language = 'de';
  static const _prefsPrefix = 'image_translations_';

  /// Translated URL for [url] in the current language (or [url] itself).
  static String url(String url) => instance.map.value[url] ?? url;

  /// Nullable convenience for optional image fields.
  static String? maybe(String? url) => url == null ? null : instance.map.value[url] ?? url;

  Future<void> load(String language) async {
    _language = language;
    if (language == 'de') {
      map.value = const {};
      return;
    }
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_prefsPrefix$language');
      if (cached != null && _language == language) {
        map.value = Map<String, String>.from(jsonDecode(cached) as Map);
      }
    } catch (_) {}

    try {
      final result = <String, String>{};
      const page = 1000;
      for (var from = 0;; from += page) {
        final rows = await Supabase.instance.client
            .from('image_translations')
            .select('source_url, url')
            .eq('language', language)
            .eq('status', 'completed')
            .range(from, from + page - 1);
        for (final r in rows) {
          final src = r['source_url'] as String?;
          final dst = r['url'] as String?;
          if (src != null && dst != null && dst.isNotEmpty) result[src] = dst;
        }
        if (rows.length < page) break;
      }
      if (_language != language) return; // switched meanwhile
      map.value = result;
      await prefs?.setString('$_prefsPrefix$language', jsonEncode(result));
    } catch (e) {
      debugPrint('[ImageLocalizer] $e');
    }
  }
}
