import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/services/favorites_service.dart';

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService.instance;
});

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  return FavoritesNotifier(ref.watch(favoritesServiceProvider));
});

class FavoritesNotifier extends StateNotifier<List<String>> {
  final FavoritesService _service;

  FavoritesNotifier(this._service) : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    state = await _service.getFavorites();
  }

  Future<void> toggleFavorite(String itemId) async {
    await _service.toggleFavorite(itemId);
    state = await _service.getFavorites();
  }

  bool isFavorite(String itemId) {
    return state.contains(itemId);
  }

  Future<void> removeFavorite(String itemId) async {
    await _service.removeFavorite(itemId);
    state = await _service.getFavorites();
  }

  Future<void> refresh() async {
    await _loadFavorites();
  }
}
