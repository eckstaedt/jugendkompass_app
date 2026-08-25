import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';

/// Registers and unregisters the device in Supabase for server-pushed
/// notifications.
///
/// The backend only stores the device_id. Push notifications are sent from
/// the server — NOT locally.
///
/// Supabase table: `device_tokens`
///   • id          (uuid, PK, auto)
///   • device_id   (text, unique)
///   • platform    (text – "ios" / "android" / "web")
///   • created_at  (timestamptz, default now())
///   • verse_notifications  (bool, default true)
///   • content_notifications (bool, default true)
///   • notification_hour (int, default 7)
///   • notification_minute (int, default 0)
class DeviceRegistrationService {
  static final DeviceRegistrationService _instance =
      DeviceRegistrationService._internal();
  static DeviceRegistrationService get instance => _instance;
  DeviceRegistrationService._internal();

  static const _table = 'device_tokens';

  /// Returns the persisted device ID, generating a new UUID if none exists.
  String get deviceId {
    var id = UserPreferencesService.instance.getDeviceId();
    if (id == null) {
      id = const Uuid().v4();
      UserPreferencesService.instance.setDeviceId(id);
    }
    return id;
  }

  /// Determine the platform string.
  String get _platform {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'web';
  }

  /// Register this device in Supabase so the server can push notifications.
  ///
  /// Uses upsert so calling it multiple times is safe.
  Future<void> register({
    bool verseNotifications = true,
    bool contentNotifications = true,
    int notificationHour = 7,
    int notificationMinute = 0,
    String? fcmToken,
    String? language,
    String? timezone,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final data = <String, dynamic>{
        'device_id': deviceId,
        'platform': _platform,
        'verse_notifications': verseNotifications,
        'content_notifications': contentNotifications,
        'notification_hour': notificationHour,
        'notification_minute': notificationMinute,
      };
      if (fcmToken != null) {
        data['fcm_token'] = fcmToken;
      }
      if (language != null) {
        data['language'] = language;
      }
      if (timezone != null) {
        data['timezone'] = timezone;
      }
      await supabase.from(_table).upsert(
        data,
        onConflict: 'device_id',
      );
      debugPrint('[DeviceRegistration] registered: $deviceId');
    } catch (e) {
      debugPrint('[DeviceRegistration] register error: $e');
    }
  }

  /// Update the notification preferences for this device on the server.
  Future<void> updatePreferences({
    bool? verseNotifications,
    bool? contentNotifications,
    int? notificationHour,
    int? notificationMinute,
    String? language,
    String? timezone,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final updates = <String, dynamic>{};
      if (verseNotifications != null) {
        updates['verse_notifications'] = verseNotifications;
      }
      if (contentNotifications != null) {
        updates['content_notifications'] = contentNotifications;
      }
      if (notificationHour != null) {
        updates['notification_hour'] = notificationHour;
      }
      if (notificationMinute != null) {
        updates['notification_minute'] = notificationMinute;
      }
      if (language != null) {
        updates['language'] = language;
      }
      if (timezone != null) {
        updates['timezone'] = timezone;
      }
      if (updates.isEmpty) return;

      await supabase
          .from(_table)
          .update(updates)
          .eq('device_id', deviceId);
      debugPrint('[DeviceRegistration] updated prefs: $updates');
    } catch (e) {
      debugPrint('[DeviceRegistration] updatePreferences error: $e');
    }
  }

  /// Update the language preference for this device.
  Future<void> updateLanguage(String language) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from(_table)
          .update({'language': language})
          .eq('device_id', deviceId);
      debugPrint('[DeviceRegistration] updated language: $language');
    } catch (e) {
      debugPrint('[DeviceRegistration] updateLanguage error: $e');
    }
  }

  /// Update the display name for this device (used to personalize push
  /// notifications, e.g. the Bible reading plan reminders).
  Future<void> updateUserName(String userName) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from(_table)
          .update({'user_name': userName})
          .eq('device_id', deviceId);
      debugPrint('[DeviceRegistration] updated user_name: $userName');
    } catch (e) {
      debugPrint('[DeviceRegistration] updateUserName error: $e');
    }
  }

  /// Marks whether the user has started the "Bibel in 365 Tagen" reading
  /// plan. Only devices with `bible_plan_started = true` are eligible for
  /// the daily reminder push (also gated by `bible_plan_notifications_enabled`).
  Future<void> updateBiblePlanStarted(bool started) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from(_table)
          .update({'bible_plan_started': started})
          .eq('device_id', deviceId);
      debugPrint('[DeviceRegistration] updated bible_plan_started: $started');
    } catch (e) {
      debugPrint('[DeviceRegistration] updateBiblePlanStarted error: $e');
    }
  }

  /// Update the "Bibelleseplan" push notification preference (on/off and/or
  /// preferred reminder hour), mirroring the Vers des Tages settings pattern.
  Future<void> updateBiblePlanNotifications({
    bool? enabled,
    int? hour,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final updates = <String, dynamic>{};
      if (enabled != null) {
        updates['bible_plan_notifications_enabled'] = enabled;
      }
      if (hour != null) {
        updates['bible_plan_notification_hour'] = hour;
      }
      if (updates.isEmpty) return;

      await supabase
          .from(_table)
          .update(updates)
          .eq('device_id', deviceId);
      debugPrint('[DeviceRegistration] updated bible plan notifications: $updates');
    } catch (e) {
      debugPrint('[DeviceRegistration] updateBiblePlanNotifications error: $e');
    }
  }

  /// Unregister this device (when user disables ALL push notifications).
  Future<void> unregister() async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from(_table).delete().eq('device_id', deviceId);
      debugPrint('[DeviceRegistration] unregistered: $deviceId');
    } catch (e) {
      debugPrint('[DeviceRegistration] unregister error: $e');
    }
  }
}
