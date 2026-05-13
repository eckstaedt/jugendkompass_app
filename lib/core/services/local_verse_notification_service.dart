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

  static String displayNameForId(String id) {
    for (final tz in commonTimezones) {
      if (tz.id == id) return tz.display;
    }
    return id;
  }
}
