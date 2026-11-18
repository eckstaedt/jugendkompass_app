import 'package:jugendkompass_app/core/localization/app_translations.dart';

/// Localized names of the 66 books of the Bible (Protestant canon order).
///
/// German names are the identifiers used by the reading plan generator.
class BibleBooks {
  BibleBooks._();

  static const List<String> _de = [
    '1. Mose', '2. Mose', '3. Mose', '4. Mose', '5. Mose', 'Josua', 'Richter',
    'Rut', '1. Samuel', '2. Samuel', '1. Könige', '2. Könige', '1. Chronik',
    '2. Chronik', 'Esra', 'Nehemia', 'Ester', 'Hiob', 'Psalm', 'Sprüche',
    'Prediger', 'Hoheslied', 'Jesaja', 'Jeremia', 'Klagelieder', 'Hesekiel',
    'Daniel', 'Hosea', 'Joel', 'Amos', 'Obadja', 'Jona', 'Micha', 'Nahum',
    'Habakuk', 'Zefanja', 'Haggai', 'Sacharja', 'Maleachi',
    'Matthäus', 'Markus', 'Lukas', 'Johannes', 'Apostelgeschichte', 'Römer',
    '1. Korinther', '2. Korinther', 'Galater', 'Epheser', 'Philipper',
    'Kolosser', '1. Thessalonicher', '2. Thessalonicher', '1. Timotheus',
    '2. Timotheus', 'Titus', 'Philemon', 'Hebräer', 'Jakobus', '1. Petrus',
    '2. Petrus', '1. Johannes', '2. Johannes', '3. Johannes', 'Judas',
    'Offenbarung',
  ];

  static const Map<AppLanguage, List<String>> _names = {
    AppLanguage.en: [
      'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua',
      'Judges', 'Ruth', '1 Samuel', '2 Samuel', '1 Kings', '2 Kings',
      '1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job',
      'Psalm', 'Proverbs', 'Ecclesiastes', 'Song of Songs', 'Isaiah',
      'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
      'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai',
      'Zechariah', 'Malachi',
      'Matthew', 'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians',
      '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians', 'Colossians',
      '1 Thessalonians', '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus',
      'Philemon', 'Hebrews', 'James', '1 Peter', '2 Peter', '1 John', '2 John',
      '3 John', 'Jude', 'Revelation',
    ],
    AppLanguage.ru: [
      'Бытие', 'Исход', 'Левит', 'Числа', 'Второзаконие', 'Иисус Навин',
      'Судьи', 'Руфь', '1 Царств', '2 Царств', '3 Царств', '4 Царств',
      '1 Паралипоменон', '2 Паралипоменон', 'Ездра', 'Неемия', 'Есфирь', 'Иов',
      'Псалом', 'Притчи', 'Екклесиаст', 'Песнь песней', 'Исаия', 'Иеремия',
      'Плач Иеремии', 'Иезекииль', 'Даниил', 'Осия', 'Иоиль', 'Амос', 'Авдий',
      'Иона', 'Михей', 'Наум', 'Аввакум', 'Софония', 'Аггей', 'Захария',
      'Малахия',
      'От Матфея', 'От Марка', 'От Луки', 'От Иоанна', 'Деяния', 'Римлянам',
      '1 Коринфянам', '2 Коринфянам', 'Галатам', 'Ефесянам', 'Филиппийцам',
      'Колоссянам', '1 Фессалоникийцам', '2 Фессалоникийцам', '1 Тимофею',
      '2 Тимофею', 'Титу', 'Филимону', 'Евреям', 'Иакова', '1 Петра',
      '2 Петра', '1 Иоанна', '2 Иоанна', '3 Иоанна', 'Иуды', 'Откровение',
    ],
    AppLanguage.es: [
      'Génesis', 'Éxodo', 'Levítico', 'Números', 'Deuteronomio', 'Josué',
      'Jueces', 'Rut', '1 Samuel', '2 Samuel', '1 Reyes', '2 Reyes',
      '1 Crónicas', '2 Crónicas', 'Esdras', 'Nehemías', 'Ester', 'Job',
      'Salmo', 'Proverbios', 'Eclesiastés', 'Cantares', 'Isaías', 'Jeremías',
      'Lamentaciones', 'Ezequiel', 'Daniel', 'Oseas', 'Joel', 'Amós', 'Abdías',
      'Jonás', 'Miqueas', 'Nahúm', 'Habacuc', 'Sofonías', 'Hageo', 'Zacarías',
      'Malaquías',
      'Mateo', 'Marcos', 'Lucas', 'Juan', 'Hechos', 'Romanos', '1 Corintios',
      '2 Corintios', 'Gálatas', 'Efesios', 'Filipenses', 'Colosenses',
      '1 Tesalonicenses', '2 Tesalonicenses', '1 Timoteo', '2 Timoteo', 'Tito',
      'Filemón', 'Hebreos', 'Santiago', '1 Pedro', '2 Pedro', '1 Juan',
      '2 Juan', '3 Juan', 'Judas', 'Apocalipsis',
    ],
    AppLanguage.pl: [
      'Rodzaju', 'Wyjścia', 'Kapłańska', 'Liczb', 'Powtórzonego Prawa',
      'Jozuego', 'Sędziów', 'Rut', '1 Samuela', '2 Samuela', '1 Królewska',
      '2 Królewska', '1 Kronik', '2 Kronik', 'Ezdrasza', 'Nehemiasza',
      'Estery', 'Hioba', 'Psalm', 'Przysłów', 'Koheleta', 'Pieśń nad Pieśniami',
      'Izajasza', 'Jeremiasza', 'Lamentacje', 'Ezechiela', 'Daniela',
      'Ozeasza', 'Joela', 'Amosa', 'Abdiasza', 'Jonasza', 'Micheasza',
      'Nahuma', 'Habakuka', 'Sofoniasza', 'Aggeusza', 'Zachariasza',
      'Malachiasza',
      'Mateusza', 'Marka', 'Łukasza', 'Jana', 'Dzieje Apostolskie', 'Rzymian',
      '1 Koryntian', '2 Koryntian', 'Galacjan', 'Efezjan', 'Filipian',
      'Kolosan', '1 Tesaloniczan', '2 Tesaloniczan', '1 Tymoteusza',
      '2 Tymoteusza', 'Tytusa', 'Filemona', 'Hebrajczyków', 'Jakuba',
      '1 Piotra', '2 Piotra', '1 Jana', '2 Jana', '3 Jana', 'Judy',
      'Apokalipsa',
    ],
    AppLanguage.tr: [
      'Yaratılış', "Mısır'dan Çıkış", 'Levililer', 'Çölde Sayım',
      "Yasa'nın Tekrarı", 'Yeşu', 'Hakimler', 'Rut', '1. Samuel', '2. Samuel',
      '1. Krallar', '2. Krallar', '1. Tarihler', '2. Tarihler', 'Ezra',
      'Nehemya', 'Ester', 'Eyüp', 'Mezmur', "Süleyman'ın Özdeyişleri", 'Vaiz',
      'Ezgiler Ezgisi', 'Yeşaya', 'Yeremya', 'Ağıtlar', 'Hezekiel', 'Daniel',
      'Hoşea', 'Yoel', 'Amos', 'Ovadya', 'Yunus', 'Mika', 'Nahum', 'Habakkuk',
      'Sefanya', 'Hagay', 'Zekeriya', 'Malaki',
      'Matta', 'Markos', 'Luka', 'Yuhanna', 'Elçilerin İşleri', 'Romalılar',
      '1. Korintliler', '2. Korintliler', 'Galatyalılar', 'Efesliler',
      'Filipililer', 'Koloseliler', '1. Selanikliler', '2. Selanikliler',
      '1. Timoteos', '2. Timoteos', 'Titus', 'Filimon', 'İbraniler', 'Yakup',
      '1. Petrus', '2. Petrus', '1. Yuhanna', '2. Yuhanna', '3. Yuhanna',
      'Yahuda', 'Vahiy',
    ],
    AppLanguage.he: [
      'בראשית', 'שמות', 'ויקרא', 'במדבר', 'דברים', 'יהושע', 'שופטים', 'רות',
      'שמואל א', 'שמואל ב', 'מלכים א', 'מלכים ב', 'דברי הימים א',
      'דברי הימים ב', 'עזרא', 'נחמיה', 'אסתר', 'איוב', 'תהלים', 'משלי',
      'קהלת', 'שיר השירים', 'ישעיהו', 'ירמיהו', 'איכה', 'יחזקאל', 'דניאל',
      'הושע', 'יואל', 'עמוס', 'עובדיה', 'יונה', 'מיכה', 'נחום', 'חבקוק',
      'צפניה', 'חגי', 'זכריה', 'מלאכי',
      'מתי', 'מרקוס', 'לוקס', 'יוחנן', 'מעשי השליחים', 'הרומים',
      'קורינתים א', 'קורינתים ב', 'הגלטים', 'האפסים', 'הפיליפים',
      'הקולוסים', 'תסלוניקים א', 'תסלוניקים ב', 'טימותיוס א', 'טימותיוס ב',
      'טיטוס', 'פילימון', 'העברים', 'יעקב', 'פטרוס א', 'פטרוס ב', 'יוחנן א',
      'יוחנן ב', 'יוחנן ג', 'יהודה', 'ההתגלות',
    ],
  };

  static final Map<String, int> _indexByGerman = {
    for (var i = 0; i < _de.length; i++) _de[i]: i,
  };

  static int get bookCount => _de.length;

  static List<String> namesFor(AppLanguage language) =>
      language == AppLanguage.de ? _de : (_names[language] ?? _de);

  /// Returns the localized book name for a German [germanName].
  static String localize(String germanName, [AppLanguage? language]) {
    final lang = language ?? AppTranslations.currentLanguage;
    if (lang == AppLanguage.de) return germanName;
    final index = _indexByGerman[germanName];
    final names = _names[lang];
    if (index == null || names == null || index >= names.length) return germanName;
    return names[index];
  }
}
