import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/user_preferences_service.dart';
import '../../core/services/device_registration_service.dart';
import '../../core/services/fcm_service.dart';
import 'supabase_provider.dart';

/// Profile repository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ProfileRepository(supabase);
});

/// Current user profile provider
final currentUserProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) return null;

  return repository.getProfile(userId);
});

/// User name provider (from local storage)
final userNameProvider = StateProvider<String?>((ref) {
  return UserPreferencesService.instance.getUserName();
});

/// Notifications enabled provider
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, bool>((ref) {
  return NotificationsNotifier(ref);
});

class NotificationsNotifier extends StateNotifier<bool> {
  final Ref _ref;

  NotificationsNotifier(this._ref) : super(false) {
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    // Check actual system permission, not just local preference
    final hasPermission = await _checkPermissionStatus();
    final localEnabled = UserPreferencesService.instance.getNotificationsEnabled();

    // State is true only if both permission is granted AND user enabled it
    state = hasPermission && localEnabled;
  }

  Future<bool> _checkPermissionStatus() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      return false;
    }
  }

  Future<void> update(bool enabled) async {
    debugPrint('[NotificationsNotifier] update called with enabled: $enabled');

    if (enabled) {
      // Request permission when enabling
      try {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                       settings.authorizationStatus == AuthorizationStatus.provisional;

        debugPrint('[NotificationsNotifier] Permission granted: $granted');

        if (!granted) {
          // Permission denied, keep state as false
          state = false;
          return;
        }

        // Permission granted, initialize FCM if needed
        try {
          await FCMService().init();
        } catch (e) {
          debugPrint('[NotificationsNotifier] FCMService init error (ignored): $e');
          // Don't return - continue even if FCM init fails
        }

        // Enable sub-toggles when main toggle is enabled
        await _ref.read(verseNotificationsProvider.notifier).update(true);
        await _ref.read(newContentNotificationsProvider.notifier).update(true);
      } catch (e) {
        // Permission request failed
        debugPrint('[NotificationsNotifier] Permission request failed: $e');
        state = false;
        return;
      }
    }

    state = enabled;
    debugPrint('[NotificationsNotifier] State set to: $enabled');
    await UserPreferencesService.instance.setNotificationsEnabled(enabled);

    try {
      if (!enabled) {
        // Unregister device from server (stops all server notifications)
        await DeviceRegistrationService.instance.unregister();
      } else {
        // Re-register on server with current settings
        final prefs = UserPreferencesService.instance;
        await DeviceRegistrationService.instance.register(
          verseNotifications: prefs.getVerseNotificationsEnabled(),
          contentNotifications: prefs.getNewContentNotificationsEnabled(),
          notificationHour: prefs.getNotificationHour(),
          notificationMinute: prefs.getNotificationMinute(),
          timezone: prefs.getTimezone(),
          language: prefs.getLanguage(),
        );
      }
    } catch (e) {
      debugPrint('[NotificationsNotifier] Server registration error: $e');
      // Silently handle errors — the toggle state is already saved
    }
  }
}

/// Provider for the notification time (hour, minute).
final notificationTimeProvider =
    StateNotifierProvider<NotificationTimeNotifier, ({int hour, int minute})>(
        (ref) {
  return NotificationTimeNotifier();
});

class NotificationTimeNotifier
    extends StateNotifier<({int hour, int minute})> {
  NotificationTimeNotifier()
      : super((
          hour: UserPreferencesService.instance.getNotificationHour(),
          minute: UserPreferencesService.instance.getNotificationMinute(),
        ));

  Future<void> update(int hour, int minute) async {
    state = (hour: hour, minute: minute);
    await UserPreferencesService.instance.setNotificationTime(hour, minute);
    final prefs = UserPreferencesService.instance;
    if (prefs.getVerseNotificationsEnabled() && prefs.getNotificationsEnabled()) {
      // Sync to server so the Edge Function uses the correct hour
      await DeviceRegistrationService.instance.updatePreferences(
        notificationHour: hour,
        notificationMinute: minute,
      );
    }
  }
}

/// Verse notifications sub-toggle (only effective when main notifications are on)
final verseNotificationsProvider =
    StateNotifierProvider<VerseNotificationsNotifier, bool>((ref) {
  return VerseNotificationsNotifier();
});

class VerseNotificationsNotifier extends StateNotifier<bool> {
  VerseNotificationsNotifier() : super(true) {
    _load();
  }

  void _load() {
    state = UserPreferencesService.instance.getVerseNotificationsEnabled();
  }

  Future<void> update(bool enabled) async {
    state = enabled;
    await UserPreferencesService.instance.setVerseNotificationsEnabled(enabled);
    // Sync to server
    await DeviceRegistrationService.instance.updatePreferences(
      verseNotifications: enabled,
    );
  }
}

/// New content notifications sub-toggle
final newContentNotificationsProvider =
    StateNotifierProvider<NewContentNotificationsNotifier, bool>((ref) {
  return NewContentNotificationsNotifier();
});

class NewContentNotificationsNotifier extends StateNotifier<bool> {
  NewContentNotificationsNotifier() : super(true) {
    _load();
  }

  void _load() {
    state =
        UserPreferencesService.instance.getNewContentNotificationsEnabled();
  }

  Future<void> update(bool enabled) async {
    state = enabled;
    await UserPreferencesService.instance
        .setNewContentNotificationsEnabled(enabled);
    // Keep server in sync for content notifications
    await DeviceRegistrationService.instance
        .updatePreferences(contentNotifications: enabled);
  }
}

/// Timezone provider (IANA timezone id, e.g. 'Europe/Berlin')
final timezoneProvider =
    StateNotifierProvider<TimezoneNotifier, String>((ref) {
  return TimezoneNotifier();
});

class TimezoneNotifier extends StateNotifier<String> {
  TimezoneNotifier() : super('Europe/Berlin') {
    _load();
  }

  void _load() {
    state = UserPreferencesService.instance.getTimezone();
  }

  Future<void> update(String timezoneId) async {
    state = timezoneId;
    await UserPreferencesService.instance.setTimezone(timezoneId);
    final prefs = UserPreferencesService.instance;
    if (prefs.getVerseNotificationsEnabled() && prefs.getNotificationsEnabled()) {
      // Sync timezone to server so the Edge Function filters correctly
      await DeviceRegistrationService.instance.updatePreferences(
        timezone: timezoneId,
      );
    }
  }
}
