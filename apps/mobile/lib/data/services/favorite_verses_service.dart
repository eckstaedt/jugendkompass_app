import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';

class FavoriteVersesService {
  static const String _favoritesKey = 'favorite_verses';
  static FavoriteVersesService? _instance;
  SharedPreferences? _prefs;

  FavoriteVersesService._();

  static FavoriteVersesService get instance {
    _instance ??= FavoriteVersesService._();
    return _instance!;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<VerseModel>> getFavoriteVerses() async {
    if (_prefs == null) await initialize();
    final jsonList = _prefs?.getStringList(_favoritesKey) ?? [];
    return jsonList.map((json) => VerseModel.fromJson(jsonDecode(json))).toList();
  }

  Future<bool> isVerseFavorite(String verseId) async {
    final favorites = await getFavoriteVerses();
    return favorites.any((v) => v.id == verseId);
  }

  Future<void> addFavoriteVerse(VerseModel verse) async {
    final favorites = await getFavoriteVerses();
    if (!favorites.any((v) => v.id == verse.id)) {
      favorites.add(verse);
      await _saveFavorites(favorites);
    }
  }

  Future<void> removeFavoriteVerse(String verseId) async {
    final favorites = await getFavoriteVerses();
    favorites.removeWhere((v) => v.id == verseId);
    await _saveFavorites(favorites);
  }

  Future<void> toggleFavoriteVerse(VerseModel verse) async {
    if (await isVerseFavorite(verse.id)) {
      await removeFavoriteVerse(verse.id);
    } else {
      await addFavoriteVerse(verse);
    }
  }

  Future<void> _saveFavorites(List<VerseModel> verses) async {
    final jsonList = verses.map((v) => jsonEncode(v.toJson())).toList();
    await _prefs?.setStringList(_favoritesKey, jsonList);
  }

  Future<void> clearAllFavorites() async {
    await _prefs?.remove(_favoritesKey);
  }
}
