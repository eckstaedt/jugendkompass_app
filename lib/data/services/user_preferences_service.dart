import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static final UserPreferencesService _instance =
      UserPreferencesService._internal();
  static UserPreferencesService get instance => _instance;

  UserPreferencesService._internal();

  SharedPreferences? _preferences;

  // Keys
  static const String _keyUserName = 'user_name';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyNotificationHour = 'notification_hour';
  static const String _keyNotificationMinute = 'notification_minute';
  static const String _keyReadingPlan = 'reading_plan_progress';
  static const String _keyLanguage = 'language';
  static const String _keyLastContentCheck = 'last_content_check';
  static const String _keyVerseNotifications = 'verse_notifications_enabled';
  static const String _keyNewContentNotifications = 'new_content_notifications_enabled';
  static const String _keyDeviceId = 'device_id';

  /// Initialize SharedPreferences
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  SharedPreferences get _prefs {
    if (_preferences == null) {
      throw Exception(
        'UserPreferencesService not initialized. Call init() first.',
      );
    }
    return _preferences!;
  }

  // User Name
  String? getUserName() {
    return _prefs.getString(_keyUserName);
  }

  Future<void> setUserName(String name) async {
    await _prefs.setString(_keyUserName, name);
  }

  // Onboarding
  bool hasCompletedOnboarding() {
    return _prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    await _prefs.setBool(_keyOnboardingComplete, true);
  }

  // Dark Mode
  bool getDarkMode() {
    return _prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool enabled) async {
    await _prefs.setBool(_keyDarkMode, enabled);
  }

  // Theme Mode (light / dark / system)
  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> setThemeModeString(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
    // keep legacy bool in sync
    if (mode == 'dark') {
      await _prefs.setBool(_keyDarkMode, true);
    } else if (mode == 'light') {
      await _prefs.setBool(_keyDarkMode, false);
    }
  }

  // Language
  String getLanguage() {
    return _prefs.getString(_keyLanguage) ?? 'de';
  }

  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(_keyLanguage, languageCode);
  }

  // Notifications
  bool getNotificationsEnabled() {
    return _prefs.getBool(_keyNotifications) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotifications, enabled);
  }

  // Notification Time
  int getNotificationHour() {
    return _prefs.getInt(_keyNotificationHour) ?? 7; // Default 07:00
  }

  int getNotificationMinute() {
    return _prefs.getInt(_keyNotificationMinute) ?? 0;
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    await _prefs.setInt(_keyNotificationHour, hour);
    await _prefs.setInt(_keyNotificationMinute, minute);
  }

  // Reading Plan Progress
  String? getReadingPlanProgress() {
    return _prefs.getString(_keyReadingPlan);
  }

  Future<void> saveReadingPlanProgress(String jsonData) async {
    await _prefs.setString(_keyReadingPlan, jsonData);
  }

  Future<void> clearReadingPlanProgress() async {
    await _prefs.remove(_keyReadingPlan);
  }

  // Last content check timestamp (ISO 8601)
  // Used by ContentPushService to detect new content since last poll.
  String? getLastContentCheck() {
    return _prefs.getString(_keyLastContentCheck);
  }

  Future<void> setLastContentCheck(String isoTimestamp) async {
    await _prefs.setString(_keyLastContentCheck, isoTimestamp);
  }

  // Verse Notifications (sub-toggle)
  bool getVerseNotificationsEnabled() {
    return _prefs.getBool(_keyVerseNotifications) ?? true;
  }

  Future<void> setVerseNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyVerseNotifications, enabled);
  }

  // New Content Notifications (sub-toggle)
  bool getNewContentNotificationsEnabled() {
    return _prefs.getBool(_keyNewContentNotifications) ?? true;
  }

  Future<void> setNewContentNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNewContentNotifications, enabled);
  }

  // Device ID (for push notification registration)
  String? getDeviceId() {
    return _prefs.getString(_keyDeviceId);
  }

  Future<void> setDeviceId(String deviceId) async {
    await _prefs.setString(_keyDeviceId, deviceId);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
