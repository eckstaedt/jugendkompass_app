class PostModel {
  // Actual database fields from Supabase posts table
  final String id;
  final String title;
  final String body;
  final String? categoryId;
  final String? categoryName; // From categories join
  final String? editionId;
  final String? contentId;
  final String? audioId;
  final String? imageUrl;

  PostModel({
    required this.id,
    required this.title,
    required this.body,
    this.categoryId,
    this.categoryName,
    this.editionId,
    this.contentId,
    this.audioId,
    this.imageUrl,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Extract category name from join if available
    String? categoryName;
    if (json['categories'] != null) {
      final categories = json['categories'];
      if (categories is List && categories.isNotEmpty) {
        categoryName = categories[0]['name'] as String?;
      } else if (categories is Map) {
        categoryName = categories['name'] as String?;
      }
    }

    return PostModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      categoryId: json['category_id']?.toString(),
      categoryName: categoryName,
      editionId: json['edition_id']?.toString(),
      contentId: json['content_id']?.toString(),
      audioId: json['audio_id']?.toString(),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category_id': categoryId,
      'edition_id': editionId,
      'content_id': contentId,
      'audio_id': audioId,
      'image_url': imageUrl,
    };
  }

  PostModel copyWith({
    String? id,
    String? title,
    String? body,
    String? categoryId,
    String? categoryName,
    String? editionId,
    String? contentId,
    String? audioId,
    String? imageUrl,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      editionId: editionId ?? this.editionId,
      contentId: contentId ?? this.contentId,
      audioId: audioId ?? this.audioId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
