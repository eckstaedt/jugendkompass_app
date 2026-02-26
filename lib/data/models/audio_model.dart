import 'post_model.dart';

class AudioModel {
  final String id;
  final String url;

  // Linked post (audios are always linked to a post)
  final PostModel? post;

  // UI-Helper Felder (werden aus posts geholt)
  final String? title;
  final String? description;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? artist;
  final String? categoryId;

  AudioModel({
    required this.id,
    required this.url,
    this.post,
    this.title,
    this.description,
    this.thumbnailUrl,
    this.durationSeconds,
    this.artist,
    this.categoryId,
  });

  factory AudioModel.fromJson(Map<String, dynamic> json) {
    // Parse post data if available
    PostModel? post;
    if (json['post'] != null) {
      post = PostModel.fromJson(json['post'] as Map<String, dynamic>);
    } else if (json['posts'] != null) {
      // Handle posts array from Supabase join
      final posts = json['posts'];
      if (posts is List && posts.isNotEmpty) {
        post = PostModel.fromJson(posts[0] as Map<String, dynamic>);
      }
    }

    return AudioModel(
      id: json['id'].toString(),
      url: json['url'] as String,
      post: post,
      // Optional Felder aus posts-Join (for backward compatibility)
      title: post?.title ?? json['title'] as String?,
      description: post?.body ?? json['description'] as String? ?? json['body'] as String?,
      thumbnailUrl: post?.imageUrl ?? json['thumbnail_url'] as String? ?? json['image_url'] as String?,
      durationSeconds: json['duration'] as int? ?? json['duration_seconds'] as int?,
      artist: json['artist'] as String?,
      categoryId: post?.categoryId ?? json['category_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'duration': durationSeconds,
      'artist': artist,
      'category_id': categoryId,
    };
  }

  // Helper getter für Audio-Wiedergabe
  String get audioUrl => url;

  // Helper getter für Thumbnail - prioritizes post image
  String? get imageUrl => post?.imageUrl ?? thumbnailUrl;

  // Helper für UI
  DateTime get createdAt => DateTime.now(); // Fallback

  Duration? get duration {
    if (durationSeconds == null) return null;
    return Duration(seconds: durationSeconds!);
  }

  AudioModel copyWith({
    String? id,
    String? url,
    PostModel? post,
    String? title,
    String? description,
    String? thumbnailUrl,
    int? durationSeconds,
    String? artist,
    String? categoryId,
  }) {
    return AudioModel(
      id: id ?? this.id,
      url: url ?? this.url,
      post: post ?? this.post,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      artist: artist ?? this.artist,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
