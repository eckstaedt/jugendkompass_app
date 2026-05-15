import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:jugendkompass_app/data/models/read_history_item_model.dart';

/// Service to track which content the user has read/played.
/// Uses SharedPreferences to persist read history locally.
class ReadHistoryService {
  static const String _historyKey = 'read_history';
  static ReadHistoryService? _instance;
  SharedPreferences? _prefs;

  // In-memory cache of read item keys for fast lookups
  Set<String> _readKeys = {};

  ReadHistoryService._();

  static ReadHistoryService get instance {
    _instance ??= ReadHistoryService._();
    return _instance!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Build in-memory cache from persisted data
    final items = await getReadHistory();
    _readKeys = items.map((item) => item.compositeKey).toSet();
  }

  /// Get all read history items
  Future<List<ReadHistoryItem>> getReadHistory() async {
    if (_prefs == null) await init();
    final jsonList = _prefs?.getStringList(_historyKey) ?? [];
    return jsonList
        .map((json) => ReadHistoryItem.fromJson(jsonDecode(json)))
        .toList();
  }

  /// Check if a specific content item has been read/played
  bool isRead(String id, ReadContentType type) {
    final key = '${type.name}_$id';
    return _readKeys.contains(key);
  }

  /// Check if a specific content item has been read/played (async version)
  Future<bool> isReadAsync(String id, ReadContentType type) async {
    if (_prefs == null) await init();
    return isRead(id, type);
  }

  /// Mark content as read/played
  Future<void> markAsRead(
    String id,
    ReadContentType type, {
    String? title,
    String? imageUrl,
  }) async {
    if (_prefs == null) await init();

    final key = '${type.name}_$id';

    // Skip if already marked as read
    if (_readKeys.contains(key)) return;

    final item = ReadHistoryItem(
      id: id,
      type: type,
      readAt: DateTime.now(),
      title: title,
      imageUrl: imageUrl,
    );

    final items = await getReadHistory();
    items.add(item);
    await _saveItems(items);

    // Update in-memory cache
    _readKeys.add(key);
  }

  /// Get all read IDs for a specific content type
  Set<String> getReadIds(ReadContentType type) {
    return _readKeys
        .where((key) => key.startsWith('${type.name}_'))
        .map((key) => key.substring(type.name.length + 1))
        .toSet();
  }

  /// Remove an item from read history
  Future<void> removeFromHistory(String id, ReadContentType type) async {
    if (_prefs == null) await init();

    final items = await getReadHistory();
    items.removeWhere((item) => item.id == id && item.type == type);
    await _saveItems(items);

    // Update in-memory cache
    _readKeys.remove('${type.name}_$id');
  }

  /// Clear all read history
  Future<void> clearHistory() async {
    if (_prefs == null) await init();
    await _prefs?.remove(_historyKey);
    _readKeys.clear();
  }

  Future<void> _saveItems(List<ReadHistoryItem> items) async {
    final jsonList = items.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs?.setStringList(_historyKey, jsonList);
  }
}
