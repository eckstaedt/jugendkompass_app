import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/edition_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/audio_model.dart';
import '../../data/repositories/edition_repository.dart';
import 'supabase_provider.dart';
import 'language_provider.dart';

/// Edition repository provider
final editionRepositoryProvider = Provider<EditionRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return EditionRepository(supabase);
});

/// All editions provider - returns localized editions based on current language
final editionsListProvider = FutureProvider<List<EditionModel>>((ref) async {
  final repository = ref.watch(editionRepositoryProvider);
  final language = ref.watch(languageProvider).locale.languageCode;
  return repository.getAllEditionsLocalized(language);
});

/// Edition detail provider (by ID) - returns localized edition
final editionDetailProvider =
    FutureProvider.family<EditionModel?, String>((ref, editionId) async {
  final repository = ref.watch(editionRepositoryProvider);
  final language = ref.watch(languageProvider).locale.languageCode;
  return repository.getEditionByIdLocalized(editionId, language);
});

/// Recent editions provider - returns localized recent editions
final recentEditionsProvider =
    FutureProvider<List<EditionModel>>((ref) async {
  final repository = ref.watch(editionRepositoryProvider);
  final language = ref.watch(languageProvider).locale.languageCode;
  // Get all localized editions and take first 10
  final allEditions = await repository.getAllEditionsLocalized(language);
  return allEditions.take(10).toList();
});

/// Edition posts provider - get all posts for a specific edition
final editionPostsProvider =
    FutureProvider.family<List<PostModel>, String>((ref, editionId) async {
  final repository = ref.watch(editionRepositoryProvider);
  final postsData = await repository.getEditionPosts(editionId);

  // Convert Map<String, dynamic> to PostModel
  return postsData.map((json) => PostModel.fromJson(json)).toList();
});

/// Edition audios provider - get all audios for posts in an edition
final editionAudiosProvider =
    FutureProvider.family<List<AudioModel>, String>((ref, editionId) async {
  final repository = ref.watch(editionRepositoryProvider);
  final audiosData = await repository.getEditionAudios(editionId);

  // Convert to AudioModel
  return audiosData.map((json) {
    // Extract posts data if available
    final posts = json['posts'];
    Map<String, dynamic>? postData;
    if (posts is List && posts.isNotEmpty) {
      postData = posts[0] as Map<String, dynamic>;
      // Add audio_id to post data
      postData['audio_id'] = json['id'];
    }

    return AudioModel.fromJson({
      'id': json['id'],
      'url': json['url'],
      'post': postData,
    });
  }).toList();
});
