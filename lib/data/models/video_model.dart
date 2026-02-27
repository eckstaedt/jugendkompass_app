class VideoModel {
  // Actual database fields from Supabase videos table
  final String id;
  final String title;
  final String? description;
  final String url;
  final String? imageUrl;
  final String contentId;
  final String? userId;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.title,
    this.description,
    required this.url,
    this.imageUrl,
    required this.contentId,
    this.userId,
    required this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      url: json['url'] as String,
      imageUrl: json['image_url'] as String?,
      contentId: json['content_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'image_url': imageUrl,
      'content_id': contentId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  VideoModel copyWith({
    String? id,
    String? title,
    String? description,
    String? url,
    String? imageUrl,
    String? contentId,
    String? userId,
    DateTime? createdAt,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      contentId: contentId ?? this.contentId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters for UI compatibility
  String get displayTitle => title.isNotEmpty ? title : 'Video';
  String? get thumbnailUrl => imageUrl; // Use imageUrl as thumbnail
  String get videoUrl => url;
}
