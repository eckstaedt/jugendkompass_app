import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for Android notification permission handling and timezone data.
///
/// Note: Verse of the day notifications are sent as remote push notifications
/// from the server, not scheduled locally. This service only handles:
/// - Android 13+ notification permission requests
/// - Timezone picker data for user preferences
class LocalVerseNotificationService {
  static final LocalVerseNotificationService instance =
      LocalVerseNotificationService._internal();
  LocalVerseNotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification plugin (needed for permission requests).
  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Request notification permission on Android 13+ (API 33+).
  /// Returns true if permission granted, false otherwise.
  Future<bool> requestAndroidPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Check if notification permission is granted on Android (without requesting).
  Future<bool> hasAndroidPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final enabled = await androidPlugin.areNotificationsEnabled();
    return enabled ?? false;
  }

  // ── Timezone picker data ─────────────────────────────────────────────────

  static const List<({String id, String display})> commonTimezones = [
    (id: 'Europe/Berlin', display: 'Deutschland • Berlin'),
    (id: 'Europe/Vienna', display: 'Österreich • Wien'),
    (id: 'Europe/Zurich', display: 'Schweiz • Zürich'),
    (id: 'Europe/London', display: 'Großbritannien • London'),
    (id: 'Europe/Paris', display: 'Frankreich • Paris'),
    (id: 'Europe/Rome', display: 'Italien • Rom'),
    (id: 'Europe/Amsterdam', display: 'Niederlande • Amsterdam'),
    (id: 'Europe/Brussels', display: 'Belgien • Brüssel'),
    (id: 'Europe/Warsaw', display: 'Polen • Warschau'),
    (id: 'Europe/Stockholm', display: 'Schweden • Stockholm'),
    (id: 'Europe/Helsinki', display: 'Finnland • Helsinki'),
    (id: 'Europe/Athens', display: 'Griechenland • Athen'),
    (id: 'Europe/Moscow', display: 'Russland • Moskau'),
    (id: 'America/New_York', display: 'USA Ostküste • New York'),
    (id: 'America/Chicago', display: 'USA Mitte • Chicago'),
    (id: 'America/Denver', display: 'USA Berg • Denver'),
    (id: 'America/Los_Angeles', display: 'USA Westküste • Los Angeles'),
    (id: 'America/Sao_Paulo', display: 'Brasilien • São Paulo'),
    (id: 'America/Argentina/Buenos_Aires', display: 'Argentinien • Buenos Aires'),
    (id: 'Asia/Jerusalem', display: 'Israel • Jerusalem'),
    (id: 'Asia/Dubai', display: 'VAE • Dubai'),
    (id: 'Asia/Kolkata', display: 'Indien • Kolkata'),
    (id: 'Asia/Shanghai', display: 'China • Shanghai'),
    (id: 'Asia/Tokyo', display: 'Japan • Tokio'),
    (id: 'Africa/Cairo', display: 'Ägypten • Kairo'),
    (id: 'Africa/Johannesburg', display: 'Südafrika • Johannesburg'),
    (id: 'Australia/Sydney', display: 'Australien • Sydney'),
    (id: 'Pacific/Auckland', display: 'Neuseeland • Auckland'),
  ];

  /// Localized timezone labels (German labels live in [commonTimezones]).
  static const Map<String, Map<String, String>> _localizedTimezoneLabels = {
    'Europe/Berlin': {'en': 'Germany • Berlin', 'ru': 'Германия • Берлин', 'es': 'Alemania • Berlín', 'pl': 'Niemcy • Berlin', 'tr': 'Almanya • Berlin', 'he': 'גרמניה • ברלין'},
    'Europe/Vienna': {'en': 'Austria • Vienna', 'ru': 'Австрия • Вена', 'es': 'Austria • Viena', 'pl': 'Austria • Wiedeń', 'tr': 'Avusturya • Viyana', 'he': 'אוסטריה • וינה'},
    'Europe/Zurich': {'en': 'Switzerland • Zurich', 'ru': 'Швейцария • Цюрих', 'es': 'Suiza • Zúrich', 'pl': 'Szwajcaria • Zurych', 'tr': 'İsviçre • Zürih', 'he': 'שווייץ • ציריך'},
    'Europe/London': {'en': 'United Kingdom • London', 'ru': 'Великобритания • Лондон', 'es': 'Reino Unido • Londres', 'pl': 'Wielka Brytania • Londyn', 'tr': 'Birleşik Krallık • Londra', 'he': 'בריטניה • לונדון'},
    'Europe/Paris': {'en': 'France • Paris', 'ru': 'Франция • Париж', 'es': 'Francia • París', 'pl': 'Francja • Paryż', 'tr': 'Fransa • Paris', 'he': 'צרפת • פריז'},
    'Europe/Rome': {'en': 'Italy • Rome', 'ru': 'Италия • Рим', 'es': 'Italia • Roma', 'pl': 'Włochy • Rzym', 'tr': 'İtalya • Roma', 'he': 'איטליה • רומא'},
    'Europe/Amsterdam': {'en': 'Netherlands • Amsterdam', 'ru': 'Нидерланды • Амстердам', 'es': 'Países Bajos • Ámsterdam', 'pl': 'Holandia • Amsterdam', 'tr': 'Hollanda • Amsterdam', 'he': 'הולנד • אמסטרדם'},
    'Europe/Brussels': {'en': 'Belgium • Brussels', 'ru': 'Бельгия • Брюссель', 'es': 'Bélgica • Bruselas', 'pl': 'Belgia • Bruksela', 'tr': 'Belçika • Brüksel', 'he': 'בלגיה • בריסל'},
    'Europe/Warsaw': {'en': 'Poland • Warsaw', 'ru': 'Польша • Варшава', 'es': 'Polonia • Varsovia', 'pl': 'Polska • Warszawa', 'tr': 'Polonya • Varşova', 'he': 'פולין • ורשה'},
    'Europe/Stockholm': {'en': 'Sweden • Stockholm', 'ru': 'Швеция • Стокгольм', 'es': 'Suecia • Estocolmo', 'pl': 'Szwecja • Sztokholm', 'tr': 'İsveç • Stockholm', 'he': 'שוודיה • שטוקהולם'},
    'Europe/Helsinki': {'en': 'Finland • Helsinki', 'ru': 'Финляндия • Хельсинки', 'es': 'Finlandia • Helsinki', 'pl': 'Finlandia • Helsinki', 'tr': 'Finlandiya • Helsinki', 'he': 'פינלנד • הלסינקי'},
    'Europe/Athens': {'en': 'Greece • Athens', 'ru': 'Греция • Афины', 'es': 'Grecia • Atenas', 'pl': 'Grecja • Ateny', 'tr': 'Yunanistan • Atina', 'he': 'יוון • אתונה'},
    'Europe/Moscow': {'en': 'Russia • Moscow', 'ru': 'Россия • Москва', 'es': 'Rusia • Moscú', 'pl': 'Rosja • Moskwa', 'tr': 'Rusya • Moskova', 'he': 'רוסיה • מוסקבה'},
    'America/New_York': {'en': 'US East Coast • New York', 'ru': 'США, восточное побережье • Нью-Йорк', 'es': 'EE. UU. costa este • Nueva York', 'pl': 'USA wschodnie wybrzeże • Nowy Jork', 'tr': 'ABD Doğu Kıyısı • New York', 'he': 'ארה״ב מזרח • ניו יורק'},
    'America/Chicago': {'en': 'US Central • Chicago', 'ru': 'США, центр • Чикаго', 'es': 'EE. UU. centro • Chicago', 'pl': 'USA środkowe • Chicago', 'tr': 'ABD Orta • Chicago', 'he': 'ארה״ב מרכז • שיקגו'},
    'America/Denver': {'en': 'US Mountain • Denver', 'ru': 'США, горное время • Денвер', 'es': 'EE. UU. montaña • Denver', 'pl': 'USA górskie • Denver', 'tr': 'ABD Dağ • Denver', 'he': 'ארה״ב הרים • דנוור'},
    'America/Los_Angeles': {'en': 'US West Coast • Los Angeles', 'ru': 'США, западное побережье • Лос-Анджелес', 'es': 'EE. UU. costa oeste • Los Ángeles', 'pl': 'USA zachodnie wybrzeże • Los Angeles', 'tr': 'ABD Batı Kıyısı • Los Angeles', 'he': 'ארה״ב מערב • לוס אנג׳לס'},
    'America/Sao_Paulo': {'en': 'Brazil • São Paulo', 'ru': 'Бразилия • Сан-Паулу', 'es': 'Brasil • São Paulo', 'pl': 'Brazylia • São Paulo', 'tr': 'Brezilya • São Paulo', 'he': 'ברזיל • סאו פאולו'},
    'America/Argentina/Buenos_Aires': {'en': 'Argentina • Buenos Aires', 'ru': 'Аргентина • Буэнос-Айрес', 'es': 'Argentina • Buenos Aires', 'pl': 'Argentyna • Buenos Aires', 'tr': 'Arjantin • Buenos Aires', 'he': 'ארגנטינה • בואנוס איירס'},
    'Asia/Jerusalem': {'en': 'Israel • Jerusalem', 'ru': 'Израиль • Иерусалим', 'es': 'Israel • Jerusalén', 'pl': 'Izrael • Jerozolima', 'tr': 'İsrail • Kudüs', 'he': 'ישראל • ירושלים'},
    'Asia/Dubai': {'en': 'UAE • Dubai', 'ru': 'ОАЭ • Дубай', 'es': 'EAU • Dubái', 'pl': 'ZEA • Dubaj', 'tr': 'BAE • Dubai', 'he': 'איחוד האמירויות • דובאי'},
    'Asia/Kolkata': {'en': 'India • Kolkata', 'ru': 'Индия • Калькутта', 'es': 'India • Calcuta', 'pl': 'Indie • Kalkuta', 'tr': 'Hindistan • Kalküta', 'he': 'הודו • קולקטה'},
    'Asia/Shanghai': {'en': 'China • Shanghai', 'ru': 'Китай • Шанхай', 'es': 'China • Shanghái', 'pl': 'Chiny • Szanghaj', 'tr': 'Çin • Şanghay', 'he': 'סין • שנגחאי'},
    'Asia/Tokyo': {'en': 'Japan • Tokyo', 'ru': 'Япония • Токио', 'es': 'Japón • Tokio', 'pl': 'Japonia • Tokio', 'tr': 'Japonya • Tokyo', 'he': 'יפן • טוקיו'},
    'Africa/Cairo': {'en': 'Egypt • Cairo', 'ru': 'Египет • Каир', 'es': 'Egipto • El Cairo', 'pl': 'Egipt • Kair', 'tr': 'Mısır • Kahire', 'he': 'מצרים • קהיר'},
    'Africa/Johannesburg': {'en': 'South Africa • Johannesburg', 'ru': 'ЮАР • Йоханнесбург', 'es': 'Sudáfrica • Johannesburgo', 'pl': 'RPA • Johannesburg', 'tr': 'Güney Afrika • Johannesburg', 'he': 'דרום אפריקה • יוהנסבורג'},
    'Australia/Sydney': {'en': 'Australia • Sydney', 'ru': 'Австралия • Сидней', 'es': 'Australia • Sídney', 'pl': 'Australia • Sydney', 'tr': 'Avustralya • Sidney', 'he': 'אוסטרליה • סידני'},
    'Pacific/Auckland': {'en': 'New Zealand • Auckland', 'ru': 'Новая Зеландия • Окленд', 'es': 'Nueva Zelanda • Auckland', 'pl': 'Nowa Zelandia • Auckland', 'tr': 'Yeni Zelanda • Auckland', 'he': 'ניו זילנד • אוקלנד'},
  };

  /// Timezone label in the given language code (falls back to German).
  static String localizedDisplay(String id, String languageCode) {
    if (languageCode != 'de') {
      final label = _localizedTimezoneLabels[id]?[languageCode];
      if (label != null) return label;
    }
    return displayNameForId(id);
  }

  static String displayNameForId(String id) {
    for (final tz in commonTimezones) {
      if (tz.id == id) return tz.display;
    }
    return id;
  }
}
