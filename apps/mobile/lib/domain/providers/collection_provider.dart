import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/collection_item_model.dart';
import 'package:jugendkompass_app/data/services/collection_service.dart';
import 'package:jugendkompass_app/domain/providers/edition_provider.dart';
import 'package:jugendkompass_app/domain/providers/impulse_provider.dart';
import 'package:jugendkompass_app/domain/providers/message_provider.dart';
import 'package:jugendkompass_app/domain/providers/post_provider.dart';

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

/// Title of a saved item in the current app language.
///
/// Saved items store the title in the language that was active when they were
/// saved. This re-reads the item through the (localized) detail providers so
/// the collection follows a language change. Returns null for items that
/// cannot be resolved (e.g. videos, deleted content) – callers fall back to
/// the stored title.
final localizedCollectionTitleProvider =
    FutureProvider.family<String?, (CollectionItemType, String)>((ref, key) async {
  final (type, id) = key;
  try {
    switch (type) {
      case CollectionItemType.post:
        return (await ref.watch(postDetailProvider(id).future))?.title;
      case CollectionItemType.impulse:
        return (await ref.watch(impulseDetailProvider(id).future))?.displayTitle;
      case CollectionItemType.edition:
        return (await ref.watch(editionDetailProvider(id).future))?.displayTitle;
      case CollectionItemType.message:
        return (await ref.watch(messageDetailProvider(id).future))?.displayTitle;
      case CollectionItemType.video:
        return null;
    }
  } catch (_) {
    return null;
  }
});
