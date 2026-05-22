class VerseModel {
  final String id;
  final String verse;
  final String reference;
  final DateTime date;
  final String? contentId;
  final String? imageUrl;

  VerseModel({
    required this.id,
    required this.verse,
    required this.reference,
    required this.date,
    this.contentId,
    this.imageUrl,
  });

  factory VerseModel.fromJson(Map<String, dynamic> json) {
    return VerseModel(
      id: json['id'].toString(),
      verse: json['verse'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      contentId: json['content_id']?.toString(),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'verse': verse,
      'reference': reference,
      'date': date.toIso8601String(),
      'content_id': contentId,
      'image_url': imageUrl,
    };
  }

  VerseModel copyWith({
    String? id,
    String? verse,
    String? reference,
    DateTime? date,
    String? contentId,
    String? imageUrl,
  }) {
    return VerseModel(
      id: id ?? this.id,
      verse: verse ?? this.verse,
      reference: reference ?? this.reference,
      date: date ?? this.date,
      contentId: contentId ?? this.contentId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
