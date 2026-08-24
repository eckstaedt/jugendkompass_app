/// A single Bible chapter to read, e.g. "1. Mose" chapter 1.
class BibleReadingChapter {
  final String book;
  final int chapter;

  const BibleReadingChapter({
    required this.book,
    required this.chapter,
  });

  /// Human readable label, e.g. "1. Mose 1".
  String get label => '$book $chapter';
}

/// One day of the "Bibel in 365 Tagen" reading plan: a day number (1-365)
/// and the individual chapters to read that day.
class BibleReadingDay {
  final int dayNumber;
  final List<BibleReadingChapter> chapters;

  const BibleReadingDay({
    required this.dayNumber,
    required this.chapters,
  });
}
