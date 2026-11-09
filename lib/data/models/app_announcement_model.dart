/// A remote-controlled, full-screen in-app announcement (table
/// `app_announcements`). Created/edited in Supabase – no app update needed.
class AppAnnouncement {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final Map<String, dynamic> translations;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool dismissible;
  final bool showOnce;

  const AppAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.imageUrl,
    required this.translations,
    required this.startsAt,
    required this.endsAt,
    required this.dismissible,
    required this.showOnce,
  });

  factory AppAnnouncement.fromJson(Map<String, dynamic> json) {
    return AppAnnouncement(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      translations: (json['translations'] as Map?)?.cast<String, dynamic>() ??
          const {},
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      dismissible: json['dismissible'] as bool? ?? true,
      showOnce: json['show_once'] as bool? ?? true,
    );
  }

  bool isActiveAt(DateTime now) =>
      !now.isBefore(startsAt) && now.isBefore(endsAt);

  String _localized(String field, String languageCode, String fallback) {
    final entry = translations[languageCode];
    if (entry is Map) {
      final value = entry[field];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return fallback;
  }

  String localizedTitle(String languageCode) =>
      _localized('title', languageCode, title);

  String localizedMessage(String languageCode) =>
      _localized('message', languageCode, message);
}
