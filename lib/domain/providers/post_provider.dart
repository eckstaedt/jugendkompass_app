import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/post_model.dart';
import 'package:jugendkompass_app/data/repositories/post_repository.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';

/// Post repository provider
final postRepositoryProvider = Provider<PostRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return PostRepository(supabase);
});

/// Posts list provider with optional filters
final postsListProvider = FutureProvider.family<List<PostModel>, PostFilter>(
  (ref, filter) async {
    final repository = ref.watch(postRepositoryProvider);
    return await repository.getPostList(
      categoryId: filter.categoryId,
      editionId: filter.editionId,
      contentId: filter.contentId,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

/// Single post provider by ID
final postDetailProvider = FutureProvider.family<PostModel?, String>(
  (ref, postId) async {
    final repository = ref.watch(postRepositoryProvider);
    return await repository.getPostById(postId);
  },
);

/// Posts by edition provider
final postsByEditionProvider = FutureProvider.family<List<PostModel>, String>(
  (ref, editionId) async {
    final repository = ref.watch(postRepositoryProvider);
    return await repository.getPostsByEdition(editionId);
  },
);

/// Post by audio ID provider
final postByAudioIdProvider = FutureProvider.family<PostModel?, String>(
  (ref, audioId) async {
    final repository = ref.watch(postRepositoryProvider);
    return await repository.getPostByAudioId(audioId);
  },
);

/// Provider that fetches the single most recent post (used on home screen)
final latestPostProvider = FutureProvider<PostModel?>((ref) async {
  final repository = ref.watch(postRepositoryProvider);
  final posts = await repository.getPostList(limit: 1);
  return posts.isNotEmpty ? posts.first : null;
});

/// Filter class for posts
class PostFilter {
  final String? categoryId;
  final String? editionId;
  final String? contentId;
  final int limit;
  final int offset;

  PostFilter({
    this.categoryId,
    this.editionId,
    this.contentId,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostFilter &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          editionId == other.editionId &&
          contentId == other.contentId &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      categoryId.hashCode ^
      editionId.hashCode ^
      contentId.hashCode ^
      limit.hashCode ^
      offset.hashCode;
}
