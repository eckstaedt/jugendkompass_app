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
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyReadingPlan = 'reading_plan_progress';

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

  // Notifications
  bool getNotificationsEnabled() {
    return _prefs.getBool(_keyNotifications) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotifications, enabled);
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

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
