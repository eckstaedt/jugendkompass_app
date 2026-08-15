import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/data/repositories/verse_repository.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/core/services/home_widget_service.dart';

final verseRepositoryProvider = Provider<VerseRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return VerseRepository(supabase);
});

final dailyVerseProvider = FutureProvider<VerseModel?>((ref) async {
  final repository = ref.watch(verseRepositoryProvider);
  final language = ref.watch(languageProvider).locale.languageCode;

  final verse = await repository.getTodaysVerseLocalized(language);

  // Sync verse to iOS Home Screen Widget
  if (verse != null) {
    await HomeWidgetService.updateVerseWidget(verse);
  }

  return verse;
});

final recentVersesProvider = FutureProvider<List<VerseModel>>((ref) async {
  final repository = ref.watch(verseRepositoryProvider);
  final language = ref.watch(languageProvider).locale.languageCode;

  return await repository.getRecentVersesLocalized(language);
});

/// Single verse provider by ID - returns localized verse based on current language
final verseByIdProvider = FutureProvider.family<VerseModel?, String>(
  (ref, verseId) async {
    final repository = ref.watch(verseRepositoryProvider);
    final language = ref.watch(languageProvider).locale.languageCode;
    return repository.getVerseByIdLocalized(verseId, language);
  },
);

/// Single verse provider by content_id (FK to the polymorphic `content`
/// table). Used for deep linking from push notifications.
final verseByContentIdProvider = FutureProvider.family<VerseModel?, String>(
  (ref, contentId) async {
    final repository = ref.watch(verseRepositoryProvider);
    return await repository.getVerseByContentId(contentId);
  },
);

/// State for the "Vers des Tages Archiv" screen: a paginated, newest-first
/// list of every verse that has ever been the verse of the day.
class VerseArchiveState {
  final List<VerseModel> verses;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  const VerseArchiveState({
    this.verses = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  VerseArchiveState copyWith({
    List<VerseModel>? verses,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return VerseArchiveState(
      verses: verses ?? this.verses,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier handling initial load, infinite-scroll pagination, and
/// pull-to-refresh for the verse archive.
class VerseArchiveNotifier extends StateNotifier<VerseArchiveState> {
  final Ref ref;
  static const int pageSize = 20;
  int _offset = 0;

  VerseArchiveNotifier(this.ref) : super(const VerseArchiveState()) {
    _loadInitial();
  }

  String get _language => ref.read(languageProvider).locale.languageCode;

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(verseRepositoryProvider);
      final verses = await repository.getVerseArchive(
        _language,
        limit: pageSize,
        offset: 0,
      );
      _offset = verses.length;
      state = state.copyWith(
        verses: verses,
        isLoading: false,
        hasMore: verses.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Loads the next page and appends it. No-op if already loading or
  /// there's nothing more to load.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final repository = ref.read(verseRepositoryProvider);
      final nextVerses = await repository.getVerseArchive(
        _language,
        limit: pageSize,
        offset: _offset,
      );
      _offset += nextVerses.length;
      state = state.copyWith(
        verses: [...state.verses, ...nextVerses],
        isLoadingMore: false,
        hasMore: nextVerses.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  /// Resets pagination and reloads from the beginning (pull-to-refresh).
  Future<void> refresh() async {
    _offset = 0;
    await _loadInitial();
  }
}

final verseArchiveProvider =
    StateNotifierProvider.autoDispose<VerseArchiveNotifier, VerseArchiveState>(
  (ref) => VerseArchiveNotifier(ref),
);

