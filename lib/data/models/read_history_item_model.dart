import 'dart:convert';

/// Content types that can be tracked as read/played
enum ReadContentType {
  post,
  video,
  audio,
  impulse,
  message,
}

/// Represents a content item that has been read or played
class ReadHistoryItem {
  final String id;
  final ReadContentType type;
  final DateTime readAt;
  final String? title;
  final String? imageUrl;

  ReadHistoryItem({
    required this.id,
    required this.type,
    required this.readAt,
    this.title,
    this.imageUrl,
  });

  /// Create a composite key for unique identification
  String get compositeKey => '${type.name}_$id';

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'readAt': readAt.toIso8601String(),
    'title': title,
    'imageUrl': imageUrl,
  };

  factory ReadHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReadHistoryItem(
      id: json['id'] as String,
      type: ReadContentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReadContentType.post,
      ),
      readAt: DateTime.parse(json['readAt'] as String),
      title: json['title'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ReadHistoryItem.fromJsonString(String jsonString) {
    return ReadHistoryItem.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadHistoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}
