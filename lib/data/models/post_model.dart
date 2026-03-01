class PostModel {
  // Actual database fields from Supabase posts table
  final String id;
  final String title;
  final String body;
  final String? categoryId;
  final String? categoryName; // From categories join (first tag or legacy)
  final List<String>? categoryNames; // support multiple tags
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
    this.categoryNames,
    this.editionId,
    this.contentId,
    this.audioId,
    this.imageUrl,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Extract category name from join if available
    String? categoryName;
    List<String>? categoryNames;
    if (json['categories'] != null) {
      final categories = json['categories'];
      if (categories is List && categories.isNotEmpty) {
        // collect all tag names
        categoryNames = categories
            .map((c) => c['name'] as String?)
            .whereType<String>()
            .toList();
        if (categoryNames.isNotEmpty) {
          categoryName = categoryNames.first;
        }
      } else if (categories is Map) {
        categoryName = categories['name'] as String?;
        if (categoryName != null) {
          categoryNames = [categoryName];
        }
      }
    }

    return PostModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      categoryId: json['category_id']?.toString(),
      categoryName: categoryName,
      categoryNames: categoryNames,
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
      // categoryNames is not directly serialized (handled by backend)
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
    List<String>? categoryNames,
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
      categoryNames: categoryNames ?? this.categoryNames,
      editionId: editionId ?? this.editionId,
      contentId: contentId ?? this.contentId,
      audioId: audioId ?? this.audioId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
