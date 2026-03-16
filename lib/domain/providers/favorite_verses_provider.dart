import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/data/services/favorite_verses_service.dart';

final favoriteVersesServiceProvider = Provider<FavoriteVersesService>((ref) {
  return FavoriteVersesService.instance;
});

final favoriteVersesProvider = StateNotifierProvider<FavoriteVersesNotifier, List<VerseModel>>((ref) {
  return FavoriteVersesNotifier(ref.watch(favoriteVersesServiceProvider));
});

class FavoriteVersesNotifier extends StateNotifier<List<VerseModel>> {
  final FavoriteVersesService _service;

  FavoriteVersesNotifier(this._service) : super([]) {
    _loadFavoriteVerses();
  }

  Future<void> _loadFavoriteVerses() async {
    state = await _service.getFavoriteVerses();
  }

  Future<void> toggleFavoriteVerse(VerseModel verse) async {
    await _service.toggleFavoriteVerse(verse);
    state = await _service.getFavoriteVerses();
  }

  bool isVerseFavorite(String verseId) {
    return state.any((v) => v.id == verseId);
  }

  Future<void> removeFavoriteVerse(String verseId) async {
    await _service.removeFavoriteVerse(verseId);
    state = await _service.getFavoriteVerses();
  }

  Future<void> refresh() async {
    await _loadFavoriteVerses();
  }
}
