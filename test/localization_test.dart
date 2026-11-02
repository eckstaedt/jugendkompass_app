import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/localization/bible_books.dart';
import 'package:jugendkompass_app/core/localization/string_translator.dart';
import 'package:jugendkompass_app/core/localization/supplement_translations.dart';

/// Collects every translation key and every `translate('<German>')` literal
/// used anywhere in lib/.
({Set<String> keys, Set<String> germanLiterals}) _scanSources() {
  final keyPatterns = [
    RegExp(r"""\btr\(\s*'([a-z0-9_]+)'"""),
    RegExp(r"""'([a-z0-9_]+)'\.tr\b"""),
    RegExp(r"""AppTranslations\.t(?:WithParams)?\(\s*'([a-z0-9_]+)'"""),
  ];
  final literalPattern = RegExp(r"""\btranslate\(\s*'((?:[^'\\]|\\.)*)'\s*\)""");

  final keys = <String>{};
  final literals = <String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.contains('${Platform.pathSeparator}localization${Platform.pathSeparator}')) continue;
    final source = entity.readAsStringSync();
    for (final pattern in keyPatterns) {
      keys.addAll(pattern.allMatches(source).map((m) => m.group(1)!));
    }
    literals.addAll(
      literalPattern.allMatches(source).map((m) => m.group(1)!.replaceAll(r"\'", "'").replaceAll(r'\n', '\n')),
    );
  }
  return (keys: keys, germanLiterals: literals);
}

void main() {
  final scan = _scanSources();

  test('every translate() literal is mapped to a key', () {
    final unmapped = scan.germanLiterals
        .where((literal) => StringTranslator.keyFor(literal) == null)
        .toList()
      ..sort();
    expect(unmapped, isEmpty, reason: 'Add these strings to StringTranslator._germanToKeyMap');
  });

  test('every UI key used in the app exists in every language', () {
    final required = {
      ...scan.keys,
      ...scan.germanLiterals.map(StringTranslator.keyFor).whereType<String>(),
    };

    final missing = <String, List<String>>{};
    for (final language in AppLanguage.values) {
      final gaps = required.where((key) => Translations.lookup(language, key) == null).toList()..sort();
      if (gaps.isNotEmpty) missing[language.name] = gaps;
    }
    expect(missing, isEmpty);
  });

  test('supplement keys are complete and keep their placeholders', () {
    final placeholder = RegExp(r'\{[a-z_]+\}');
    supplementTranslations.forEach((key, values) {
      for (final language in AppLanguage.values) {
        expect(values[language.locale.languageCode], isNotNull, reason: '$key missing ${language.name}');
      }
      final expected = placeholder.allMatches(values['de']!).map((m) => m.group(0)).toSet();
      values.forEach((lang, value) {
        final actual = placeholder.allMatches(value).map((m) => m.group(0)).toSet();
        expect(actual, expected, reason: '$key/$lang placeholders');
      });
    });
  });

  test('parameters are substituted', () {
    final translations = Translations(AppLanguage.en);
    expect(translations.getWithParams('day_number', {'day': '12'}), 'Day 12');
  });

  test('bible book names exist for all 66 books in every language', () {
    for (final language in AppLanguage.values) {
      expect(BibleBooks.namesFor(language).length, BibleBooks.bookCount, reason: language.name);
    }
    expect(BibleBooks.localize('Johannes', AppLanguage.en), 'John');
    expect(BibleBooks.localize('1. Korinther', AppLanguage.es), '1 Corintios');
    expect(BibleBooks.localize('Psalm', AppLanguage.de), 'Psalm');
  });
}
