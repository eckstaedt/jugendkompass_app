import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Schedules and manages a local daily notification for "Vers des Tages".
///
/// Completely local — no server involved.
/// Works on iOS and Android. On web it is a no-op.
class LocalVerseNotificationService {
  static final LocalVerseNotificationService instance =
      LocalVerseNotificationService._internal();
  LocalVerseNotificationService._internal();

  static const int _notificationId = 1001;
  static const String _channelId = 'verse_of_day';
  static const String _channelName = 'Vers des Tages';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Must be called once at app start (before scheduling).
  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    // Load the timezone database
    tz_data.initializeTimeZones();

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
  /// On iOS this is a no-op (iOS permissions are handled via Firebase).
  Future<bool> requestAndroidPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Check if notification permission is granted on Android (without requesting).
  /// Returns true if granted or not on Android.
  Future<bool> hasAndroidPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final enabled = await androidPlugin.areNotificationsEnabled();
    return enabled ?? false;
  }

  /// Schedule (or reschedule) a daily notification at [hour]:[minute]
  /// in the given IANA [timezoneId] (e.g. 'Europe/Berlin').
  /// Only schedules if permission is already granted (does not request).
  Future<void> scheduleDaily(int hour, int minute, String timezoneId) async {
    if (kIsWeb) return;

    // Check if permission is granted (don't request at startup)
    if (Platform.isAndroid) {
      final hasPermission = await hasAndroidPermission();
      if (!hasPermission) return;
    }

    await cancel();

    tz.Location location;
    try {
      location = tz.getLocation(timezoneId);
    } catch (_) {
      location = tz.getLocation('Europe/Berlin');
    }

    final now = tz.TZDateTime.now(location);
    var scheduledDate =
        tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Try to fetch today's verse for a meaningful notification body
    String notificationBody = 'Dein täglicher Bibelvers wartet auf dich.';
    try {
      final language = UserPreferencesService.instance.getLanguage();
      final supabase = Supabase.instance.client;
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      Map<String, dynamic>? row;
      if (language == 'de') {
        row = await supabase
            .from('verse_of_the_day')
            .select('verse, reference')
            .eq('date', todayStr)
            .maybeSingle();
        row ??= await supabase
            .from('verse_of_the_day')
            .select('verse, reference')
            .order('date', ascending: false)
            .limit(1)
            .maybeSingle();
      } else {
        final result = await supabase
            .rpc('get_verse_of_day_localized', params: {'lang': language});
        if (result != null && result is List && result.isNotEmpty) {
          row = result.first as Map<String, dynamic>;
        }
        row ??= await supabase
            .from('verse_of_the_day')
            .select('verse, reference')
            .eq('date', todayStr)
            .maybeSingle();
      }

      if (row != null) {
        final verse = row['verse'] as String?;
        final reference = row['reference'] as String?;
        if (verse != null && verse.isNotEmpty) {
          notificationBody = reference != null && reference.isNotEmpty
              ? '$verse — $reference'
              : verse;
        }
      }
    } catch (e) {
      debugPrint('[LocalVerse] Could not fetch verse for notification: $e');
    }

    try {
      await _plugin.zonedSchedule(
        _notificationId,
        'Vers des Tages 📖',
        notificationBody,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Tägliche Bibelvers-Erinnerung',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[LocalVerse] Failed to schedule notification: $e');
    }
  }

  /// Cancel the verse notification.
  Future<void> cancel() async {
    if (kIsWeb) return;
    await _plugin.cancel(_notificationId);
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
