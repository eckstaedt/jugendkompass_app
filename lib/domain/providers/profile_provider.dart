import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/user_preferences_service.dart';
import '../../core/services/device_registration_service.dart';
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
        // Unregister device from server — no more push notifications
        await DeviceRegistrationService.instance.unregister();
      } else {
        // Register device with server for push notifications
        final prefs = UserPreferencesService.instance;
        await DeviceRegistrationService.instance.register(
          verseNotifications: prefs.getVerseNotificationsEnabled(),
          contentNotifications: prefs.getNewContentNotificationsEnabled(),
          notificationHour: prefs.getNotificationHour(),
          notificationMinute: prefs.getNotificationMinute(),
        );
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
    // Server reads this preference from device_tokens table
    await DeviceRegistrationService.instance
        .updatePreferences(verseNotifications: enabled);
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
  }
}
