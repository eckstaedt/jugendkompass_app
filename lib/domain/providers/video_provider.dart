import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/video_model.dart';
import 'package:jugendkompass_app/data/repositories/video_repository.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';

/// Video repository provider
final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return VideoRepository(supabase);
});

/// Videos list provider
final videosListProvider = FutureProvider<List<VideoModel>>((ref) async {
  final repository = ref.watch(videoRepositoryProvider);
  return repository.getVideoList(limit: 100);
});

/// Single video provider by ID
final videoByIdProvider = FutureProvider.family<VideoModel?, String>(
  (ref, videoId) async {
    final repository = ref.watch(videoRepositoryProvider);
    return repository.getVideoById(videoId);
  },
);

/// Video by content ID provider
final videoByContentIdProvider = FutureProvider.family<VideoModel?, String>(
  (ref, contentId) async {
    final repository = ref.watch(videoRepositoryProvider);
    return repository.getVideoByContentId(contentId);
  },
);
