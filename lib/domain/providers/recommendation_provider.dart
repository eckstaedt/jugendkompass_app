import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/post_model.dart';
import 'package:jugendkompass_app/data/models/video_model.dart';
import 'package:jugendkompass_app/domain/providers/post_provider.dart';
import 'package:jugendkompass_app/domain/providers/video_provider.dart';

// Model for recommended content items (Posts = Artikel with/without Audio, Videos)
class RecommendedItem {
  final dynamic data; // PostModel or VideoModel
  final String contentType; // 'post' or 'video'

  RecommendedItem({
    required this.data,
    required this.contentType,
  });

  factory RecommendedItem.fromPost(PostModel post) {
    return RecommendedItem(
      data: post,
      contentType: 'post',
    );
  }

  factory RecommendedItem.fromVideo(VideoModel video) {
    return RecommendedItem(
      data: video,
      contentType: 'video',
    );
  }

  String get id {
    if (contentType == 'video') {
      return (data as VideoModel).id;
    }
    return (data as PostModel).id;
  }

  String get title {
    if (contentType == 'video') {
      return (data as VideoModel).title;
    }
    return (data as PostModel).title;
  }

  String? get imageUrl {
    if (contentType == 'video') {
      return (data as VideoModel).thumbnailUrl;
    }
    return (data as PostModel).imageUrl;
  }

  String? get audioId {
    if (contentType == 'video') return null;
    return (data as PostModel).audioId;
  }

  String? get categoryName {
    if (contentType == 'video') return null;
    return (data as PostModel).categoryName;
  }

  // Getter to get the actual model
  PostModel? get post => contentType == 'post' ? data as PostModel : null;
  VideoModel? get video => contentType == 'video' ? data as VideoModel : null;

  bool get hasAudio => contentType == 'post' && (data as PostModel).audioId != null;
  bool get isVideo => contentType == 'video';
  bool get isArticle => contentType == 'post' && !hasAudio;
}

final recommendedContentProvider = FutureProvider<List<RecommendedItem>>((ref) async {
  try {
    // Fetch posts (articles with and without audio)
    final postRepository = ref.watch(postRepositoryProvider);
    final posts = await postRepository.getPostList(limit: 8);

    // Fetch videos
    final videoRepository = ref.watch(videoRepositoryProvider);
    final videos = await videoRepository.getVideoList(limit: 100);

    // Convert to RecommendedItems
    final postItems = posts.map((post) => RecommendedItem.fromPost(post)).toList();
    final videoItems = videos.take(2).map((video) => RecommendedItem.fromVideo(video)).toList();

    // Combine and shuffle
    final combined = [...postItems, ...videoItems];
    combined.shuffle();

    return combined.take(10).toList();
  } catch (e) {
    throw Exception('Fehler beim Laden der Empfehlungen: $e');
  }
});
