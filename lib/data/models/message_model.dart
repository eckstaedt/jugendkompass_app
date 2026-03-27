class MessageModel {
  final String id;
  final String? title;
  final String message;
  final String? contentId;
  final String? imageUrl;
  final String? createdBy;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    this.title,
    required this.message,
    this.contentId,
    this.imageUrl,
    this.createdBy,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'].toString(),
      title: json['title'] as String?,
      message: json['message'] as String? ?? '',
      contentId: json['content_id']?.toString(),
      imageUrl: json['image_url'] as String?,
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'content_id': contentId,
      'image_url': imageUrl,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? title,
    String? message,
    String? contentId,
    String? imageUrl,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      contentId: contentId ?? this.contentId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Strip HTML tags from a string
  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  /// Plain text version of the message (HTML stripped)
  String get plainText => _stripHtml(message);

  // Helper getters for UI compatibility
  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    final text = plainText;
    return text.length > 80 ? '${text.substring(0, 80)}…' : text;
  }

  String get body => message;
}
