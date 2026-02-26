class EditionModel {
  // Direct fields from editions table
  final String id;
  final String name; // Main identifier (e.g., "JK 01.2021")
  final String? title; // Display title (e.g., "Jugendkompass: Aufbruch 2026")
  final String? body; // Description text
  final String? imageUrl; // Cover image
  final String? pdfUrl; // PDF download link
  final DateTime? publishedAt;

  const EditionModel({
    required this.id,
    required this.name,
    this.title,
    this.body,
    this.imageUrl,
    this.pdfUrl,
    this.publishedAt,
  });

  factory EditionModel.fromJson(Map<String, dynamic> json) {
    return EditionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String?,
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      pdfUrl: json['pdf_url'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'pdf_url': pdfUrl,
      'published_at': publishedAt?.toIso8601String(),
    };
  }

  EditionModel copyWith({
    String? id,
    String? name,
    String? title,
    String? body,
    String? imageUrl,
    String? pdfUrl,
    DateTime? publishedAt,
  }) {
    return EditionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  // Helper getters for UI compatibility
  String get displayTitle => title ?? name;
  String? get description => body;
  String? get coverImageUrl => imageUrl;
  String? get issueNumber => name; // Use name as issue number (e.g., "JK 01.2021")
  DateTime get publishedDate => publishedAt ?? DateTime.now();

  @override
  String toString() {
    return 'EditionModel(id: $id, name: $name, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EditionModel &&
        other.id == id &&
        other.name == name &&
        other.title == title;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ title.hashCode;
  }
}
