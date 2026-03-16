import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/recommendation_provider.dart';

/// Pagination state for recent content with lazy loading support
class PaginationState {
  final List<RecommendedItem> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;

  PaginationState({
    required this.items,
    required this.isLoading,
    required this.hasMore,
    required this.currentPage,
  });

  PaginationState copyWith({
    List<RecommendedItem>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
  }) {
    return PaginationState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Pagination notifier for lazy loading recent content
class PaginationNotifier extends StateNotifier<PaginationState> {
  final Ref ref;
  static const int pageSize = 10;

  PaginationNotifier(this.ref)
      : super(PaginationState(
          items: [],
          isLoading: false,
          hasMore: true,
          currentPage: 1,
        )) {
    _loadInitialPage();
  }

  Future<void> _loadInitialPage() async {
    state = state.copyWith(isLoading: true);
    final recentContent = await ref.read(recentContentProvider.future);
    final paginated = recentContent.take(pageSize).toList();

    state = state.copyWith(
      items: paginated,
      isLoading: false,
      hasMore: recentContent.length > pageSize,
      currentPage: 1,
    );
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final recentContent = await ref.read(recentContentProvider.future);

    final startIndex = state.currentPage * pageSize;
    final endIndex = startIndex + pageSize;
    final nextPageItems = recentContent.sublist(
      startIndex,
      endIndex > recentContent.length ? recentContent.length : endIndex,
    );

    state = state.copyWith(
      items: [...state.items, ...nextPageItems],
      isLoading: false,
      hasMore: endIndex < recentContent.length,
      currentPage: state.currentPage + 1,
    );
  }
}

/// Provider for paginated recent content
final paginatedRecentContentProvider =
    StateNotifierProvider<PaginationNotifier, PaginationState>((ref) {
  return PaginationNotifier(ref);
});
