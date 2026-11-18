import 'package:shared_preferences/shared_preferences.dart';

/// Recent search queries, stored on the device (newest first, max 10).
class SearchHistoryService {
  SearchHistoryService._();

  static const _key = 'search_history';
  static const int maxEntries = 10;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  static Future<List<String>> add(String query) async {
    final q = query.trim();
    final list = [...await load()];
    if (q.length < 2) return list;
    list.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    list.insert(0, q);
    if (list.length > maxEntries) list.removeRange(maxEntries, list.length);
    await (await SharedPreferences.getInstance()).setStringList(_key, list);
    return list;
  }

  static Future<List<String>> remove(String query) async {
    final list = [...await load()]..remove(query);
    await (await SharedPreferences.getInstance()).setStringList(_key, list);
    return list;
  }

  static Future<void> clear() async {
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}
