class SupabaseConstants {
  // Table names
  static const String verseOfTheDayTable = 'verse_of_the_day';
  static const String contentTable = 'content';
  static const String postsTable = 'posts';
  static const String audiosTable = 'audios';
  static const String impulsesTable = 'impulses';
  static const String categoriesTable = 'categories';
  static const String profilesTable = 'profiles';
  static const String activitiesTable = 'activities';
  static const String editionsTable = 'editions';

  // Column names for current_verse
  static const String verseId = 'id';
  static const String verseContent = 'verse';
  static const String verseReference = 'reference';
  static const String verseDate = 'date';
  static const String verseContentId = 'content_id';

  // Column names for content
  static const String contentId = 'id';
  static const String contentTitle = 'title';
  static const String contentDescription = 'description';
  static const String contentType = 'content_type';
  static const String contentUrl = 'content_url';
  static const String contentThumbnail = 'thumbnail_url';
  static const String contentCategoryId = 'category_id';
  static const String contentCreatedAt = 'created_at';

  // Column names for audios
  static const String audioId = 'id';
  static const String audioTitle = 'title';
  static const String audioUrl = 'audio_url';
  static const String audioDescription = 'description';
  static const String audioThumbnail = 'thumbnail_url';
  static const String audioDuration = 'duration';
  static const String audioCreatedAt = 'created_at';
}
