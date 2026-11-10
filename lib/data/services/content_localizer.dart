import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Applies server-side translations to raw Supabase rows.
///
/// German (`de`) is the source language and lives in the original tables.
/// Every other language is stored by the translation worker in:
///   * `content_translations` (content_id, language, field_name, value)
///     → posts, messages, impulses, videos, verses, polls (+ `option:<id>`)
///   * `entity_translations` (entity_type, entity_id, language, field_name, value)
///     → editions, categories
///
/// All repositories load the German rows exactly like in the German code path
/// and then call one of the `localize*` methods. This keeps the data shape
/// identical for every language and falls back to German per field whenever a
/// translation is not (yet) available. Failures never break loading — the
/// German original is shown instead.
class ContentLocalizer {
  ContentLocalizer(this._supabase);

  /// Shared instance per Supabase client so all repositories share one cache.
  static ContentLocalizer forClient(SupabaseClient client) {
    final existing = _shared;
    if (existing != null && identical(existing._supabase, client)) return existing;
    return _shared = ContentLocalizer(client);
  }

  static ContentLocalizer? _shared;

  /// Drops cached translations of the shared instance (e.g. pull-to-refresh).
  static void clearSharedCache() => _shared?.clearCache();

  final SupabaseClient _supabase;

  static const String sourceLanguage = 'de';
  static const int _chunkSize = 80;
  static const Duration _cacheTtl = Duration(minutes: 3);

  // language|content_id → field → value
  final Map<String, _CacheEntry> _contentCache = {};
  // type|language|entity_id → field → value
  final Map<String, _CacheEntry> _entityCache = {};

  static bool needsTranslation(String language) =>
      language.isNotEmpty && language != sourceLanguage;

  /// Overlays translated values onto [rows] (mutated in place and returned).
  ///
  /// [fields] maps the JSON key in the row to the `field_name` stored in
  /// `content_translations` – usually identical (e.g. `{'title': 'title'}`).
  Future<List<Map<String, dynamic>>> localizeContentRows(
    List<Map<String, dynamic>> rows,
    String language, {
    required Map<String, String> fields,
    String contentIdKey = 'content_id',
  }) async {
    if (!needsTranslation(language) || rows.isEmpty) return rows;

    final ids = rows
        .map((row) => row[contentIdKey]?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    if (ids.isEmpty) return rows;

    final translations = await _fetchContentTranslations(ids, language);
    for (final row in rows) {
      final contentId = row[contentIdKey]?.toString();
      final values = contentId == null ? null : translations[contentId];
      if (values == null) continue;
      fields.forEach((jsonKey, fieldName) {
        final value = values[fieldName];
        if (value != null && value.trim().isNotEmpty) row[jsonKey] = value;
      });
    }
    return rows;
  }

  /// Replaces `url` of `audios` rows with the dubbed audio for [language]
  /// (uploaded in the translation panel → `audio_translations`). Rows without
  /// a dubbed version keep the German original.
  Future<List<Map<String, dynamic>>> localizeAudioUrls(
    List<Map<String, dynamic>> rows,
    String language, {
    String idKey = 'id',
    String urlKey = 'url',
  }) async {
    if (!needsTranslation(language) || rows.isEmpty) return rows;
    final ids = rows.map((row) => row[idKey]?.toString()).whereType<String>().where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return rows;

    try {
      final urls = <String, String>{};
      for (var i = 0; i < ids.length; i += _chunkSize) {
        final chunk = ids.sublist(i, i + _chunkSize > ids.length ? ids.length : i + _chunkSize);
        final response = await _supabase
            .from('audio_translations')
            .select('audio_id, url')
            .eq('language', language)
            .inFilter('audio_id', chunk);
        for (final raw in response as List) {
          final url = raw['url']?.toString();
          if (url != null && url.isNotEmpty) urls[raw['audio_id'].toString()] = url;
        }
      }
      for (final row in rows) {
        final translated = urls[row[idKey]?.toString()];
        if (translated != null) row[urlKey] = translated;
      }
    } catch (e) {
      developer.log('audio translations unavailable: $e', name: 'ContentLocalizer');
    }
    return rows;
  }

  Future<Map<String, dynamic>?> localizeContentRow(
    Map<String, dynamic>? row,
    String language, {
    required Map<String, String> fields,
    String contentIdKey = 'content_id',
  }) async {
    if (row == null) return null;
    await localizeContentRows([row], language, fields: fields, contentIdKey: contentIdKey);
    return row;
  }

  /// Polls: translates `question` and every option in `poll_options`
  /// (stored as `option:<option_id>` under the poll's content_id).
  Future<List<Map<String, dynamic>>> localizePolls(
    List<Map<String, dynamic>> polls,
    String language,
  ) async {
    if (!needsTranslation(language) || polls.isEmpty) return polls;

    final ids = polls
        .map((poll) => poll['content_id']?.toString())
        .whereType<String>()
        .toSet();
    if (ids.isEmpty) return polls;

    final translations = await _fetchContentTranslations(ids, language);
    for (final poll in polls) {
      final values = translations[poll['content_id']?.toString()];
      if (values == null) continue;

      final question = values['question'];
      if (question != null && question.trim().isNotEmpty) poll['question'] = question;

      final options = poll['poll_options'];
      if (options is List) {
        for (final option in options) {
          if (option is! Map) continue;
          final text = values['option:${option['id']}'];
          if (text != null && text.trim().isNotEmpty) option['option_text'] = text;
        }
      }
    }
    return polls;
  }

  /// Editions / categories (rows without content_id).
  Future<List<Map<String, dynamic>>> localizeEntityRows(
    List<Map<String, dynamic>> rows,
    String language, {
    required String entityType,
    required Map<String, String> fields,
    String idKey = 'id',
  }) async {
    if (!needsTranslation(language) || rows.isEmpty) return rows;

    final ids = rows
        .map((row) => row[idKey]?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    if (ids.isEmpty) return rows;

    final translations = await _fetchEntityTranslations(entityType, ids, language);
    for (final row in rows) {
      final values = translations[row[idKey]?.toString()];
      if (values == null) continue;
      fields.forEach((jsonKey, fieldName) {
        final value = values[fieldName];
        if (value != null && value.trim().isNotEmpty) row[jsonKey] = value;
      });
    }
    return rows;
  }

  /// Translates nested category joins (`categories: {...}` or `[...]`) in rows.
  Future<void> localizeNestedCategories(
    List<Map<String, dynamic>> rows,
    String language, {
    String key = 'categories',
  }) async {
    if (!needsTranslation(language) || rows.isEmpty) return;

    final categoryMaps = <Map<String, dynamic>>[];
    for (final row in rows) {
      final value = row[key];
      if (value is Map) {
        categoryMaps.add(value.cast<String, dynamic>());
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) categoryMaps.add(item.cast<String, dynamic>());
        }
      }
    }
    if (categoryMaps.isEmpty) return;

    await localizeEntityRows(
      categoryMaps,
      language,
      entityType: 'category',
      fields: const {'name': 'name'},
    );
  }

  /// Translates a single text field of one content item (e.g. audio title).
  Future<Map<String, String>> translationsForContent(String contentId, String language) async {
    if (!needsTranslation(language) || contentId.isEmpty) return const {};
    final result = await _fetchContentTranslations({contentId}, language);
    return result[contentId] ?? const {};
  }

  void clearCache() {
    _contentCache.clear();
    _entityCache.clear();
  }

  // ── Fetching ──────────────────────────────────────────────────────────────

  Future<Map<String, Map<String, String>>> _fetchContentTranslations(
    Set<String> contentIds,
    String language,
  ) async {
    final result = <String, Map<String, String>>{};
    final missing = <String>[];

    for (final id in contentIds) {
      final cached = _contentCache['$language|$id'];
      if (cached != null && !cached.isExpired) {
        result[id] = cached.values;
      } else {
        missing.add(id);
      }
    }
    if (missing.isEmpty) return result;

    try {
      for (var i = 0; i < missing.length; i += _chunkSize) {
        final chunk = missing.sublist(i, (i + _chunkSize).clamp(0, missing.length));
        final response = await _supabase
            .from('content_translations')
            .select('content_id, field_name, value')
            .eq('language', language)
            .inFilter('content_id', chunk);

        final fetched = <String, Map<String, String>>{for (final id in chunk) id: {}};
        for (final row in response as List) {
          final id = row['content_id']?.toString();
          final field = row['field_name'] as String?;
          final value = row['value'] as String?;
          if (id == null || field == null || value == null) continue;
          (fetched[id] ??= {})[field] = value;
        }
        fetched.forEach((id, values) {
          _contentCache['$language|$id'] = _CacheEntry(values);
          result[id] = values;
        });
      }
    } catch (e) {
      developer.log('content translations unavailable: $e', name: 'ContentLocalizer');
    }
    return result;
  }

  Future<Map<String, Map<String, String>>> _fetchEntityTranslations(
    String entityType,
    Set<String> entityIds,
    String language,
  ) async {
    final result = <String, Map<String, String>>{};
    final missing = <String>[];

    for (final id in entityIds) {
      final cached = _entityCache['$entityType|$language|$id'];
      if (cached != null && !cached.isExpired) {
        result[id] = cached.values;
      } else {
        missing.add(id);
      }
    }
    if (missing.isEmpty) return result;

    try {
      for (var i = 0; i < missing.length; i += _chunkSize) {
        final chunk = missing.sublist(i, (i + _chunkSize).clamp(0, missing.length));
        final response = await _supabase
            .from('entity_translations')
            .select('entity_id, field_name, value')
            .eq('entity_type', entityType)
            .eq('language', language)
            .inFilter('entity_id', chunk);

        final fetched = <String, Map<String, String>>{for (final id in chunk) id: {}};
        for (final row in response as List) {
          final id = row['entity_id']?.toString();
          final field = row['field_name'] as String?;
          final value = row['value'] as String?;
          if (id == null || field == null || value == null) continue;
          (fetched[id] ??= {})[field] = value;
        }
        fetched.forEach((id, values) {
          _entityCache['$entityType|$language|$id'] = _CacheEntry(values);
          result[id] = values;
        });
      }
    } catch (e) {
      developer.log('entity translations unavailable: $e', name: 'ContentLocalizer');
    }
    return result;
  }
}

class _CacheEntry {
  _CacheEntry(this.values) : createdAt = DateTime.now();

  final Map<String, String> values;
  final DateTime createdAt;

  bool get isExpired => DateTime.now().difference(createdAt) > ContentLocalizer._cacheTtl;
}
