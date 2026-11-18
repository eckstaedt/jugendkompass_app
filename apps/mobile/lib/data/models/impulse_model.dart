class ImpulseModel {
  // Direct fields from impulses table
  final String id;
  final String contentId;
  final String title; // Required field in impulses table
  final DateTime date; // Required date field
  final String impulseText;
  final String? imageUrl; // Nullable in impulses table
  final DateTime createdAt;

  // Optional fields from content table (via content_id FK join)
  final String? status;

  ImpulseModel({
    required this.id,
    required this.contentId,
    required this.title,
    required this.date,
    required this.impulseText,
    this.imageUrl,
    required this.createdAt,
    this.status,
  });

  factory ImpulseModel.fromJson(Map<String, dynamic> json) {
    return ImpulseModel(
      id: json['id'].toString(),
      contentId: json['content_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      impulseText: json['impulse_text'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      status: json['status'] as String?, // From content table join
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'title': title,
      'date': date.toIso8601String().split('T')[0], // Date only (YYYY-MM-DD)
      'impulse_text': impulseText,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper getters for UI
  String get displayTitle => title.isNotEmpty ? title : 'Impuls';

  // Calculate duration based on text length
  // Rough estimate: 150 words per minute, average 5 chars per word
  int get durationMinutes {
    final wordCount = impulseText.split(RegExp(r'\s+')).length;
    final minutes = (wordCount / 150).ceil();
    return minutes > 0 ? minutes : 1; // Minimum 1 minute
  }

  String get durationLabel => '$durationMinutes MIN';

  bool get isPublished => status?.toLowerCase() == 'published';
}
