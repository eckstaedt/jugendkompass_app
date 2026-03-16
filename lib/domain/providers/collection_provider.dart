import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/collection_item_model.dart';
import 'package:jugendkompass_app/data/services/collection_service.dart';

final collectionServiceProvider = Provider<CollectionService>((ref) {
  return CollectionService.instance;
});

final collectionProvider =
    StateNotifierProvider<CollectionNotifier, List<CollectionItem>>((ref) {
  return CollectionNotifier(ref.watch(collectionServiceProvider));
});

class CollectionNotifier extends StateNotifier<List<CollectionItem>> {
  final CollectionService _service;

  CollectionNotifier(this._service) : super([]) {
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    state = await _service.getCollectionItems();
  }

  Future<void> toggleCollection(CollectionItem item) async {
    await _service.toggleCollection(item);
    state = await _service.getCollectionItems();
  }

  bool isInCollection(String itemId, CollectionItemType type) {
    return state.any((item) => item.id == itemId && item.type == type);
  }

  Future<void> removeFromCollection(String itemId, CollectionItemType type) async {
    await _service.removeFromCollection(itemId, type);
    state = await _service.getCollectionItems();
  }

  Future<void> refresh() async {
    await _loadCollection();
  }
}
