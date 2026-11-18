import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:jugendkompass_app/data/models/collection_item_model.dart';

class CollectionService {
  static const String _collectionKey = 'collection_items';
  static CollectionService? _instance;
  SharedPreferences? _prefs;

  CollectionService._();

  static CollectionService get instance {
    _instance ??= CollectionService._();
    return _instance!;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<CollectionItem>> getCollectionItems() async {
    if (_prefs == null) await initialize();
    final jsonList = _prefs?.getStringList(_collectionKey) ?? [];
    return jsonList
        .map((json) => CollectionItem.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<bool> isItemInCollection(String itemId, CollectionItemType type) async {
    final items = await getCollectionItems();
    return items.any((item) => item.id == itemId && item.type == type);
  }

  Future<void> addToCollection(CollectionItem item) async {
    final items = await getCollectionItems();
    if (!items.any((i) => i.id == item.id && i.type == item.type)) {
      items.add(item);
      await _saveItems(items);
    }
  }

  Future<void> removeFromCollection(String itemId, CollectionItemType type) async {
    final items = await getCollectionItems();
    items.removeWhere((item) => item.id == itemId && item.type == type);
    await _saveItems(items);
  }

  Future<void> toggleCollection(CollectionItem item) async {
    if (await isItemInCollection(item.id, item.type)) {
      await removeFromCollection(item.id, item.type);
    } else {
      await addToCollection(item);
    }
  }

  Future<void> _saveItems(List<CollectionItem> items) async {
    final jsonList = items.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs?.setStringList(_collectionKey, jsonList);
  }

  Future<void> clearAllItems() async {
    await _prefs?.remove(_collectionKey);
  }
}
