class MessageModel {
  final String id;
  final String message;
  final String? contentId;
  final String? imageUrl;
  final String? createdBy;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.message,
    this.contentId,
    this.imageUrl,
    this.createdBy,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'].toString(),
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
      'message': message,
      'content_id': contentId,
      'image_url': imageUrl,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? message,
    String? contentId,
    String? imageUrl,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      message: message ?? this.message,
      contentId: contentId ?? this.contentId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters for UI compatibility
  String get displayTitle => message.length > 80 ? '${message.substring(0, 80)}…' : message;
  String get body => message;
}
