enum CollectionItemType {
  impulse,
  video,
  post,
  edition,
  message,
}

class CollectionItem {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final CollectionItemType type;
  final String? author;
  final DateTime savedAt;
  final Map<String, dynamic>? rawData;

  CollectionItem({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.type,
    this.author,
    required this.savedAt,
    this.rawData,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      type: CollectionItemType.values.firstWhere(
        (e) => e.toString() == 'CollectionItemType.${json['type']}',
      ),
      author: json['author'] as String?,
      savedAt: DateTime.parse(json['saved_at'] as String),
      rawData: json['raw_data'] != null ? Map<String, dynamic>.from(json['raw_data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'type': type.toString().split('.').last,
      'author': author,
      'saved_at': savedAt.toIso8601String(),
      'raw_data': rawData,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}
