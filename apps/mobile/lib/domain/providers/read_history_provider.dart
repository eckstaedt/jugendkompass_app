import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/read_history_item_model.dart';
import 'package:jugendkompass_app/data/services/read_history_service.dart';
import 'package:jugendkompass_app/core/services/content_interaction_service.dart';

/// Provider for the ReadHistoryService singleton
final readHistoryServiceProvider = Provider<ReadHistoryService>((ref) {
  return ReadHistoryService.instance;
});

/// StateNotifier provider for read history with reactive updates
final readHistoryProvider =
    StateNotifierProvider<ReadHistoryNotifier, List<ReadHistoryItem>>((ref) {
  return ReadHistoryNotifier(ref.watch(readHistoryServiceProvider));
});

/// Check if specific content is read - use for UI opacity
final isContentReadProvider =
    Provider.family<bool, ({String id, ReadContentType type})>((ref, params) {
  // Watch the history state to rebuild when it changes
  ref.watch(readHistoryProvider);
  final service = ref.watch(readHistoryServiceProvider);
  return service.isRead(params.id, params.type);
});

/// Get all read IDs for a specific content type
final readIdsForTypeProvider =
    Provider.family<Set<String>, ReadContentType>((ref, type) {
  // Watch the history to rebuild when it changes
  ref.watch(readHistoryProvider);
  final service = ref.watch(readHistoryServiceProvider);
  return service.getReadIds(type);
});

class ReadHistoryNotifier extends StateNotifier<List<ReadHistoryItem>> {
  final ReadHistoryService _service;

  ReadHistoryNotifier(this._service) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    state = await _service.getReadHistory();
  }

  /// Mark content as read and update state
  Future<void> markAsRead(
    String id,
    ReadContentType type, {
    String? title,
    String? imageUrl,
  }) async {
    // Track locally
    await _service.markAsRead(id, type, title: title, imageUrl: imageUrl);

    // Track to database (fire and forget, won't block UI)
    ContentInteractionService.instance.trackInteraction(
      contentId: id,
      contentType: type.name,
      title: title,
    );

    state = await _service.getReadHistory();
  }

  /// Check if content is read (synchronous, uses cached data)
  bool isRead(String id, ReadContentType type) {
    return _service.isRead(id, type);
  }

  /// Remove from history
  Future<void> removeFromHistory(String id, ReadContentType type) async {
    await _service.removeFromHistory(id, type);
    state = await _service.getReadHistory();
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _service.clearHistory();
    state = [];
  }

  /// Refresh from storage
  Future<void> refresh() async {
    await _loadHistory();
  }
}
