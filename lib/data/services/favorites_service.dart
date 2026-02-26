import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorites';
  static FavoritesService? _instance;
  SharedPreferences? _prefs;

  FavoritesService._();

  static FavoritesService get instance {
    _instance ??= FavoritesService._();
    return _instance!;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<String>> getFavorites() async {
    if (_prefs == null) await initialize();
    return _prefs?.getStringList(_favoritesKey) ?? [];
  }

  Future<bool> isFavorite(String itemId) async {
    final favorites = await getFavorites();
    return favorites.contains(itemId);
  }

  Future<void> addFavorite(String itemId) async {
    final favorites = await getFavorites();
    if (!favorites.contains(itemId)) {
      favorites.add(itemId);
      await _prefs?.setStringList(_favoritesKey, favorites);
    }
  }

  Future<void> removeFavorite(String itemId) async {
    final favorites = await getFavorites();
    favorites.remove(itemId);
    await _prefs?.setStringList(_favoritesKey, favorites);
  }

  Future<void> toggleFavorite(String itemId) async {
    if (await isFavorite(itemId)) {
      await removeFavorite(itemId);
    } else {
      await addFavorite(itemId);
    }
  }

  Future<void> clearAllFavorites() async {
    await _prefs?.remove(_favoritesKey);
  }
}
