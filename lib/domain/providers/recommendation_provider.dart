import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/post_model.dart';
import 'package:jugendkompass_app/data/models/video_model.dart';
import 'package:jugendkompass_app/data/models/message_model.dart';
import 'package:jugendkompass_app/domain/providers/post_provider.dart';
import 'package:jugendkompass_app/domain/providers/video_provider.dart';
import 'package:jugendkompass_app/domain/providers/message_provider.dart';

// Model for recommended content items (Posts = Artikel with/without Audio, Videos, Messages = Kurznachrichten)
class RecommendedItem {
  final dynamic data; // PostModel, VideoModel, or MessageModel
  final String contentType; // 'post', 'video', or 'message'

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

  factory RecommendedItem.fromMessage(MessageModel message) {
    return RecommendedItem(
      data: message,
      contentType: 'message',
    );
  }

  String get id {
    if (contentType == 'video') {
      return (data as VideoModel).id;
    }
    if (contentType == 'message') {
      return (data as MessageModel).id;
    }
    return (data as PostModel).id;
  }

  String get title {
    if (contentType == 'video') {
      return (data as VideoModel).title;
    }
    if (contentType == 'message') {
      // Use title if available, otherwise stripped plain text
      return (data as MessageModel).displayTitle;
    }
    return (data as PostModel).title;
  }

  String? get imageUrl {
    if (contentType == 'video') {
      return (data as VideoModel).thumbnailUrl;
    }
    if (contentType == 'message') {
      return (data as MessageModel).imageUrl;
    }
    return (data as PostModel).imageUrl;
  }

  String? get audioId {
    if (contentType == 'video') return null;
    if (contentType == 'message') return null;
    return (data as PostModel).audioId;
  }

  String? get categoryName {
    if (contentType == 'video') return null;
    if (contentType == 'message') return null;
    return (data as PostModel).categoryName;
  }

  // Getter to get the actual model
  PostModel? get post => contentType == 'post' ? data as PostModel : null;
  VideoModel? get video => contentType == 'video' ? data as VideoModel : null;
  MessageModel? get message => contentType == 'message' ? data as MessageModel : null;

  bool get hasAudio => contentType == 'post' && (data as PostModel).audioId != null;
  bool get isVideo => contentType == 'video';
  bool get isArticle => contentType == 'post' && !hasAudio;
  bool get isMessage => contentType == 'message';
  
  /// Whether this is a Kurznachricht (either a message or a post with news category)
  bool get isKurznachricht {
    if (contentType == 'message') return true;
    if (contentType != 'post') return false;
    final p = data as PostModel;
    // Kurznachrichten: posts with category "news" or without audio/image and short body
    final categories = p.categoryNames ?? (p.categoryName != null ? [p.categoryName!] : []);
    return categories.any((c) => c.toLowerCase() == 'news' || c.toLowerCase() == 'kurznachricht' || c.toLowerCase() == 'kurznachrichten');
  }

  DateTime get createdAt {
    if (contentType == 'video') {
      return (data as VideoModel).createdAt;
    }
    if (contentType == 'message') {
      return (data as MessageModel).createdAt;
    }
    return (data as PostModel).createdAt;
  }
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

/// Paginated content provider - fetches all content (posts, videos, messages) sorted by date
/// Returns batches of items. Parameter is the page number (0-indexed).
final paginatedContentProvider = FutureProvider.family<List<RecommendedItem>, int>((ref, page) async {
  try {
    final postRepository = ref.watch(postRepositoryProvider);
    final videoRepository = ref.watch(videoRepositoryProvider);
    final messageRepository = ref.watch(messageRepositoryProvider);
    
    final batchSize = 50;
    final posts = await postRepository.getPostList(limit: batchSize, offset: page * batchSize);
    final videos = await videoRepository.getVideoList(limit: batchSize, offset: page * batchSize);
    final messages = await messageRepository.getMessageList(limit: batchSize, offset: page * batchSize);

    // Convert to RecommendedItems and deduplicate within the batch
    final seen = <String>{};
    final allItems = <RecommendedItem>[];
    
    for (final post in posts) {
      final key = 'post_${post.id}';
      if (seen.add(key)) {
        allItems.add(RecommendedItem.fromPost(post));
      }
    }
    
    for (final video in videos) {
      final key = 'video_${video.id}';
      if (seen.add(key)) {
        allItems.add(RecommendedItem.fromVideo(video));
      }
    }

    for (final message in messages) {
      final key = 'message_${message.id}';
      if (seen.add(key)) {
        allItems.add(RecommendedItem.fromMessage(message));
      }
    }

    // Sort by creation date (newest first)
    allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return allItems;
  } catch (e) {
    return [];
  }
});

/// Latest content provider - returns the newest content item across all types
final latestContentProvider = FutureProvider<RecommendedItem?>((ref) async {
  try {
    // Fetch posts, videos, and messages
    final postRepository = ref.watch(postRepositoryProvider);
    final videoRepository = ref.watch(videoRepositoryProvider);
    final messageRepository = ref.watch(messageRepositoryProvider);
    
    final posts = await postRepository.getPostList(limit: 30);
    final videos = await videoRepository.getVideoList(limit: 30);
    final messages = await messageRepository.getMessageList(limit: 30);

    // Convert to RecommendedItems
    final allItems = <RecommendedItem>[];
    
    // Add posts with their creation timestamps
    for (final post in posts) {
      allItems.add(RecommendedItem.fromPost(post));
    }
    
    // Add videos with their creation timestamps
    for (final video in videos) {
      allItems.add(RecommendedItem.fromVideo(video));
    }

    // Add messages with their creation timestamps
    for (final message in messages) {
      allItems.add(RecommendedItem.fromMessage(message));
    }

    // Sort by creation date (newest first)
    allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return allItems.isNotEmpty ? allItems.first : null;
  } catch (e) {
    return null;
  }
});

/// Recent content provider - returns content from last 4 weeks (excluding the latest one), sorted by date descending
final recentContentProvider = FutureProvider<List<RecommendedItem>>((ref) async {
  try {
    // Fetch posts, videos, and messages
    final postRepository = ref.watch(postRepositoryProvider);
    final videoRepository = ref.watch(videoRepositoryProvider);
    final messageRepository = ref.watch(messageRepositoryProvider);
    
    final posts = await postRepository.getPostList(limit: 30);
    final videos = await videoRepository.getVideoList(limit: 30);
    final messages = await messageRepository.getMessageList(limit: 30);

    // Convert to RecommendedItems
    final allItems = <RecommendedItem>[];
    
    // Add posts
    for (final post in posts) {
      allItems.add(RecommendedItem.fromPost(post));
    }
    
    // Add videos
    for (final video in videos) {
      allItems.add(RecommendedItem.fromVideo(video));
    }

    // Add messages
    for (final message in messages) {
      allItems.add(RecommendedItem.fromMessage(message));
    }

    // Sort by creation date (newest first)
    allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Filter: only items from last 4 weeks, excluding the first (newest) one
    final fourWeeksAgo = DateTime.now().subtract(const Duration(days: 28));
    final filtered = allItems
        .skip(1) // Skip the newest item
        .where((item) => item.createdAt.isAfter(fourWeeksAgo))
        .toList();

    // Already sorted by date descending (newest first)
    return filtered;
  } catch (e) {
    return [];
  }
});
