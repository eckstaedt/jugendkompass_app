import 'package:flutter_test/flutter_test.dart';
import 'package:jugendkompass_app/core/utils/search_utils.dart';

SearchMatch? m(String q, {String title = '', String body = '', String extra = ''}) =>
    SearchMatcher.match(SearchQuery.parse(q), SearchText(title: title, body: body, extra: extra));

void main() {
  group('normalize', () {
    test('folds case, umlauts, accents and punctuation', () {
      expect(SearchText.normalize('Mädchen, Größe!'), 'maedchen groesse');
      expect(SearchText.normalize('José   Ñandú'), 'jose nandu');
      expect(SearchText.normalize('Ёлка'), 'елка');
      expect(SearchText.normalize('Psalm 23,1'), 'psalm 23 1');
    });
  });

  group('matching', () {
    test('umlaut spelling variants find each other', () {
      expect(m('maedchen', title: 'Mädchen im Glauben'), isNotNull);
      expect(m('Mädchen', body: 'Ein Maedchen erzählt'), isNotNull);
    });

    test('all words must occur, in any order', () {
      expect(m('jesus gnade', body: 'Die Gnade, die Jesus schenkt'), isNotNull);
      expect(m('jesus zorn', body: 'Die Gnade, die Jesus schenkt'), isNull);
    });

    test('quoted phrase must occur exactly', () {
      expect(m('"gott der heerscharen"', body: 'HERR, Gott der Heerscharen ist sein Name'), isNotNull);
      expect(m('"heerscharen gott"', body: 'HERR, Gott der Heerscharen ist sein Name'), isNull);
    });

    test('finds parts of words (kreuz → Kreuzes)', () {
      expect(m('kreuz', title: 'Die Kraft des Kreuzes'), isNotNull);
    });

    test('searches extra fields like tags and references', () {
      expect(m('leitthema', title: 'Der Kampf um dein Herz', extra: 'Leitthema'), isNotNull);
      expect(m('psalm 143', title: 'Um deines Namens willen', extra: 'Psalm 143,11'), isNotNull);
    });

    test('title hit ranks above body hit, whole word above part', () {
      final inTitle = m('gnade', title: 'Gnade', body: '')!.score;
      final inBody = m('gnade', title: 'Andacht', body: 'Gnade für dich')!.score;
      final partial = m('gnade', title: 'Begnadet', body: '')!.score;
      expect(inTitle, greaterThan(inBody));
      expect(inTitle, greaterThan(partial));
    });

    test('empty query matches everything', () {
      expect(m('   ', title: 'x'), isNotNull);
    });
  });

  group('snippet & highlight', () {
    test('snippet is cut around the first hit', () {
      final body = '${'Vorher ' * 30}hier steht das Wort Erweckung mitten im Text ${'danach ' * 30}';
      final s = SearchMatcher.snippet(body, SearchQuery.parse('erweckung'))!;
      expect(s, contains('Erweckung'));
      expect(s.startsWith('… '), isTrue);
      expect(s.endsWith(' …'), isTrue);
      expect(s.length, lessThan(220));
    });

    test('body hit returns a snippet, title hit does not', () {
      expect(m('erweckung', title: 'X', body: 'Jugend braucht Erweckung')!.snippet, contains('Erweckung'));
      expect(m('kreuz', title: 'Kreuz', body: 'nichts')!.snippet, isNull);
    });

    test('highlight marks matching words', () {
      final parts = SearchMatcher.highlight('Die Kraft des Kreuzes', SearchQuery.parse('kreuz'));
      expect(parts.where((p) => p.$2).map((p) => p.$1), ['Kreuzes']);
      expect(parts.map((p) => p.$1).join(), 'Die Kraft des Kreuzes');
    });
  });
}
