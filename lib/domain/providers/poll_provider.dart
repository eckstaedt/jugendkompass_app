import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/data/models/poll_model.dart';
import 'package:jugendkompass_app/data/models/poll_vote_model.dart';
import 'package:jugendkompass_app/data/repositories/poll_repository.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';

/// Provider for PollRepository
final pollRepositoryProvider = Provider<PollRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return PollRepository(supabase);
});

/// Provider for active polls list
final activePollListProvider = FutureProvider.autoDispose<List<PollModel>>((ref) async {
  final repository = ref.watch(pollRepositoryProvider);
  final language = ref.watch(languageProvider).locale.languageCode;
  return repository.getPollList(activeOnly: true, language: language);
});

/// Provider for fetching a single poll by ID
final pollByIdProvider = FutureProvider.family<PollModel?, String>((ref, id) async {
  final repository = ref.watch(pollRepositoryProvider);
  final language = ref.watch(languageProvider).locale.languageCode;
  return repository.getPollById(id, language: language);
});

/// Provider for fetching a single poll by content_id
final pollByContentIdProvider =
    FutureProvider.family<PollModel?, String>((ref, contentId) async {
  final repository = ref.watch(pollRepositoryProvider);
  final language = ref.watch(languageProvider).locale.languageCode;
  return repository.getPollByContentId(contentId, language: language);
});

/// Provider for checking user's vote on a specific poll
final userVoteProvider = FutureProvider.family<PollVoteModel?, String>((ref, pollId) async {
  final repository = ref.watch(pollRepositoryProvider);
  final supabase = ref.watch(supabaseProvider);
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return null;

  return repository.getUserVote(pollId, userId);
});

/// Provider for submitting poll votes
class PollVoteNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state
  }

  Future<void> submitVote(String pollId, String optionId) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(pollRepositoryProvider);
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception(AppTranslations.t('login_to_vote'));
      }

      await repository.submitVote(pollId, optionId, userId);

      // Invalidate poll and vote data to refresh
      ref.invalidate(pollByIdProvider(pollId));
      ref.invalidate(userVoteProvider(pollId));
      ref.invalidate(activePollListProvider);

      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final pollVoteNotifierProvider = AutoDisposeAsyncNotifierProvider<PollVoteNotifier, void>(() {
  return PollVoteNotifier();
});
