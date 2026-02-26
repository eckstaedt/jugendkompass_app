class ContentModel {
  // Actual database fields from Supabase content table
  final String id;
  final String contentType;
  final String status;
  final DateTime createdAt;

  // Fields from joined posts table (via content_id FK)
  final String? title;
  final String? body;
  final String? imageUrl;
  final String? categoryId;
  final String? editionId;
  final String? audioId;

  ContentModel({
    required this.id,
    required this.contentType,
    required this.status,
    required this.createdAt,
    this.title,
    this.body,
    this.imageUrl,
    this.categoryId,
    this.editionId,
    this.audioId,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id'].toString(),
      contentType: json['content_type'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      title: json['title'] as String?,
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      categoryId: json['category_id']?.toString(),
      editionId: json['edition_id']?.toString(),
      audioId: json['audio_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_type': contentType,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'category_id': categoryId,
      'edition_id': editionId,
      'audio_id': audioId,
    };
  }

  // Helper getters for UI compatibility
  String get displayTitle => title ?? 'Ohne Titel';
  String? get description => body;
  String? get thumbnailUrl => imageUrl;
  String? get subtitle => null; // Not in database
  String? get contentUrl => null; // Use audioId to fetch from audios table if needed

  // Type checking helpers
  bool get isPost => contentType.toLowerCase() == 'post';
  bool get isVerse => contentType.toLowerCase() == 'verse';
  bool get isImpulse => contentType.toLowerCase() == 'impulse';
  bool get isPoll => contentType.toLowerCase() == 'poll';
  bool get isVideo => contentType.toLowerCase() == 'video';
  bool get isAudio => contentType.toLowerCase() == 'audio' || audioId != null;
  bool get isMessage => contentType.toLowerCase() == 'message';

  bool get isPublished => status.toLowerCase() == 'published';
}
