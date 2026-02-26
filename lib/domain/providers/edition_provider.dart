import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/edition_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/audio_model.dart';
import '../../data/repositories/edition_repository.dart';
import 'supabase_provider.dart';

/// Edition repository provider
final editionRepositoryProvider = Provider<EditionRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return EditionRepository(supabase);
});

/// All editions provider
final editionsListProvider = FutureProvider<List<EditionModel>>((ref) async {
  final repository = ref.watch(editionRepositoryProvider);
  return repository.getAllEditions();
});

/// Edition detail provider (by ID)
final editionDetailProvider =
    FutureProvider.family<EditionModel?, String>((ref, editionId) async {
  final repository = ref.watch(editionRepositoryProvider);
  return repository.getEditionById(editionId);
});

/// Recent editions provider
final recentEditionsProvider =
    FutureProvider<List<EditionModel>>((ref) async {
  final repository = ref.watch(editionRepositoryProvider);
  return repository.getRecentEditions(limit: 10);
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
