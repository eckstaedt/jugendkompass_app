import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/user_preferences_service.dart';
import '../../core/services/device_registration_service.dart';
import '../../core/services/local_verse_notification_service.dart';
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
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true) {
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    state = UserPreferencesService.instance.getNotificationsEnabled();
  }

  Future<void> update(bool enabled) async {
    state = enabled;
    await UserPreferencesService.instance.setNotificationsEnabled(enabled);

    try {
      if (!enabled) {
        // Cancel local verse notification fallback
        await LocalVerseNotificationService.instance.cancel();
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
        // Schedule local verse notification as offline fallback
        if (prefs.getVerseNotificationsEnabled()) {
          await LocalVerseNotificationService.instance.scheduleDaily(
            prefs.getNotificationHour(),
            prefs.getNotificationMinute(),
            prefs.getTimezone(),
          );
        }
      }
    } catch (e) {
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
      // Keep local notification as offline fallback
      await LocalVerseNotificationService.instance.scheduleDaily(
        hour,
        minute,
        prefs.getTimezone(),
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
    // Local fallback: schedule or cancel
    if (enabled) {
      final prefs = UserPreferencesService.instance;
      await LocalVerseNotificationService.instance.scheduleDaily(
        prefs.getNotificationHour(),
        prefs.getNotificationMinute(),
        prefs.getTimezone(),
      );
    } else {
      await LocalVerseNotificationService.instance.cancel();
    }
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
      // Keep local fallback in sync
      await LocalVerseNotificationService.instance.scheduleDaily(
        prefs.getNotificationHour(),
        prefs.getNotificationMinute(),
        timezoneId,
      );
    }
  }
}
