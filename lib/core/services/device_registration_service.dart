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
