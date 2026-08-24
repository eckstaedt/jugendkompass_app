/// A single continuous chapter range within one Bible book,
/// e.g. "1. Mose 1-3" or "Psalm 23".
class BibleReadingRange {
  final String book;
  final int startChapter;
  final int endChapter;

  const BibleReadingRange({
    required this.book,
    required this.startChapter,
    required this.endChapter,
  });

  /// Human readable label, e.g. "1. Mose 1–3" or "Psalm 23".
  String get label => endChapter > startChapter
      ? '$book $startChapter–$endChapter'
      : '$book $startChapter';
}

/// One day of the "Bibel in 365 Tagen" reading plan: a day number (1-365)
/// and the list of chapter ranges to read that day.
class BibleReadingDay {
  final int dayNumber;
  final List<BibleReadingRange> readings;

  const BibleReadingDay({
    required this.dayNumber,
    required this.readings,
  });
}
