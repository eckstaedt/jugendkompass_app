import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/core/services/device_registration_service.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service for tracking app analytics (installs and app openings).
///
/// Sends anonymous analytics data to Supabase for tracking:
/// - App installs (first launch)
/// - App openings (every launch)
///
/// Uses device_id from DeviceRegistrationService for identification.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();
  AnalyticsService._internal();

  static const _table = 'app_analytics';
  static const _installTrackedKey = 'analytics_install_tracked';

  /// Track an app opening event.
  ///
  /// Should be called on every app startup.
  Future<void> trackAppOpen() async {
    try {
      final deviceId = DeviceRegistrationService.instance.deviceId;
      final platform = _platform;
      final appVersion = await _getAppVersion();

      await Supabase.instance.client.from(_table).insert({
        'device_id': deviceId,
        'event_type': 'app_open',
        'platform': platform,
        'app_version': appVersion,
      });

      debugPrint('[Analytics] App open tracked for device: ${deviceId.substring(0, 8)}...');
    } catch (e) {
      debugPrint('[Analytics] Error tracking app open: $e');
      // Don't throw - analytics should never break the app
    }
  }

  /// Track an app install event.
  ///
  /// Only tracks once per device (first launch).
  /// Should be called on app startup - will check if already tracked.
  Future<void> trackInstallIfNeeded() async {
    try {
      // Check if install was already tracked
      final hasTrackedInstall = UserPreferencesService.instance
          .getBool(_installTrackedKey) ?? false;

      if (hasTrackedInstall) {
        debugPrint('[Analytics] Install already tracked, skipping');
        return;
      }

      final deviceId = DeviceRegistrationService.instance.deviceId;
      final platform = _platform;
      final appVersion = await _getAppVersion();

      await Supabase.instance.client.from(_table).insert({
        'device_id': deviceId,
        'event_type': 'install',
        'platform': platform,
        'app_version': appVersion,
      });

      // Mark as tracked
      await UserPreferencesService.instance.setBool(_installTrackedKey, true);

      debugPrint('[Analytics] Install tracked for device: ${deviceId.substring(0, 8)}...');
    } catch (e) {
      debugPrint('[Analytics] Error tracking install: $e');
      // Don't throw - analytics should never break the app
    }
  }

  /// Get the platform string.
  String get _platform {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'web';
  }

  /// Get the current app version.
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      debugPrint('[Analytics] Error getting app version: $e');
      return 'unknown';
    }
  }

  /// Get analytics summary (admin only - will fail if not admin).
  ///
  /// Returns a map with:
  /// - total_installs: Total unique devices that installed
  /// - total_app_opens: Total app opening events
  /// - unique_devices: Total unique devices that used the app
  /// - installs_last_7_days: New installs in last 7 days
  /// - installs_last_30_days: New installs in last 30 days
  /// - app_opens_last_7_days: App opens in last 7 days
  /// - app_opens_last_30_days: App opens in last 30 days
  /// - avg_opens_per_device: Average opens per device
  /// - platforms: Device count per platform
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final response = await Supabase.instance.client.rpc('get_analytics_summary');
      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Analytics] Error fetching analytics summary: $e');
      rethrow;
    }
  }
}
