import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/services/like_service.dart';

export 'package:jugendkompass_app/core/services/like_service.dart' show LikeState;

/// Unique key for a likeable content item.
typedef LikeKey = ({String id, String type});

/// Provider family: one notifier per (contentId, contentType) pair.
final likeProvider =
    AsyncNotifierProvider.family<LikeNotifier, LikeState, LikeKey>(
  LikeNotifier.new,
);

class LikeNotifier extends FamilyAsyncNotifier<LikeState, LikeKey> {
  @override
  Future<LikeState> build(LikeKey arg) {
    return LikeService.instance.getLikeState(arg.id, arg.type);
  }

  /// Optimistically toggle and sync with server.
  Future<void> toggle() async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic update
    final optimistic = LikeState(
      liked: !current.liked,
      likeCount: current.likeCount + (current.liked ? -1 : 1),
    );
    state = AsyncData(optimistic);

    try {
      final result =
          await LikeService.instance.toggleLike(arg.id, arg.type);
      state = AsyncData(result);
    } catch (_) {
      // Roll back
      state = AsyncData(current);
    }
  }
}
