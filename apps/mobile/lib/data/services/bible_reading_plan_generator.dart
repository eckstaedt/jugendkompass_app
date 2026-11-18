import 'package:jugendkompass_app/data/models/bible_reading_plan_model.dart';

class _BibleBook {
  final String name;
  final int chapters;
  const _BibleBook(this.name, this.chapters);
}

/// Generates the static "Bibel in 365 Tagen" reading plan.
///
/// The plan is built deterministically by flattening every chapter of every
/// book (in canonical order) into a single list and then distributing that
/// list evenly across 365 days (using cumulative rounding so the total
/// number of chapters read matches exactly, with no gaps or repeats).
class BibleReadingPlanGenerator {
  static const int totalDays = 365;

  /// German book names with their canonical chapter counts.
  /// Total: 929 (AT) + 260 (NT) = 1189 chapters.
  static const List<_BibleBook> _books = [
    // ── Altes Testament ──
    _BibleBook('1. Mose', 50),
    _BibleBook('2. Mose', 40),
    _BibleBook('3. Mose', 27),
    _BibleBook('4. Mose', 36),
    _BibleBook('5. Mose', 34),
    _BibleBook('Josua', 24),
    _BibleBook('Richter', 21),
    _BibleBook('Rut', 4),
    _BibleBook('1. Samuel', 31),
    _BibleBook('2. Samuel', 24),
    _BibleBook('1. Könige', 22),
    _BibleBook('2. Könige', 25),
    _BibleBook('1. Chronik', 29),
    _BibleBook('2. Chronik', 36),
    _BibleBook('Esra', 10),
    _BibleBook('Nehemia', 13),
    _BibleBook('Ester', 10),
    _BibleBook('Hiob', 42),
    _BibleBook('Psalm', 150),
    _BibleBook('Sprüche', 31),
    _BibleBook('Prediger', 12),
    _BibleBook('Hoheslied', 8),
    _BibleBook('Jesaja', 66),
    _BibleBook('Jeremia', 52),
    _BibleBook('Klagelieder', 5),
    _BibleBook('Hesekiel', 48),
    _BibleBook('Daniel', 12),
    _BibleBook('Hosea', 14),
    _BibleBook('Joel', 3),
    _BibleBook('Amos', 9),
    _BibleBook('Obadja', 1),
    _BibleBook('Jona', 4),
    _BibleBook('Micha', 7),
    _BibleBook('Nahum', 3),
    _BibleBook('Habakuk', 3),
    _BibleBook('Zefanja', 3),
    _BibleBook('Haggai', 2),
    _BibleBook('Sacharja', 14),
    _BibleBook('Maleachi', 4),

    // ── Neues Testament ──
    _BibleBook('Matthäus', 28),
    _BibleBook('Markus', 16),
    _BibleBook('Lukas', 24),
    _BibleBook('Johannes', 21),
    _BibleBook('Apostelgeschichte', 28),
    _BibleBook('Römer', 16),
    _BibleBook('1. Korinther', 16),
    _BibleBook('2. Korinther', 13),
    _BibleBook('Galater', 6),
    _BibleBook('Epheser', 6),
    _BibleBook('Philipper', 4),
    _BibleBook('Kolosser', 4),
    _BibleBook('1. Thessalonicher', 5),
    _BibleBook('2. Thessalonicher', 3),
    _BibleBook('1. Timotheus', 6),
    _BibleBook('2. Timotheus', 4),
    _BibleBook('Titus', 3),
    _BibleBook('Philemon', 1),
    _BibleBook('Hebräer', 13),
    _BibleBook('Jakobus', 5),
    _BibleBook('1. Petrus', 5),
    _BibleBook('2. Petrus', 3),
    _BibleBook('1. Johannes', 5),
    _BibleBook('2. Johannes', 1),
    _BibleBook('3. Johannes', 1),
    _BibleBook('Judas', 1),
    _BibleBook('Offenbarung', 22),
  ];

  static List<BibleReadingDay>? _cached;

  /// Returns the full 365-day reading plan (memoized after first call).
  static List<BibleReadingDay> generate() {
    final cached = _cached;
    if (cached != null) return cached;

    // Flatten every (book, chapterNumber) pair in canonical order.
    final flat = <MapEntry<String, int>>[];
    for (final book in _books) {
      for (int chapter = 1; chapter <= book.chapters; chapter++) {
        flat.add(MapEntry(book.name, chapter));
      }
    }

    final totalChapters = flat.length;
    final days = <BibleReadingDay>[];
    int previousBoundary = 0;

    for (int day = 1; day <= totalDays; day++) {
      final boundary = (day * totalChapters / totalDays).round();
      final slice = flat.sublist(previousBoundary, boundary);
      previousBoundary = boundary;

      days.add(BibleReadingDay(
        dayNumber: day,
        chapters: slice
            .map((entry) => BibleReadingChapter(book: entry.key, chapter: entry.value))
            .toList(),
      ));
    }

    _cached = days;
    return days;
  }
}
