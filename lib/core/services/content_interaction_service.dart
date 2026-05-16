import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/core/services/device_registration_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service for tracking content interactions (clicks/views) to Supabase.
///
/// Sends anonymous interaction data using device_id for tracking:
/// - Post reads
/// - Video views
/// - Audio plays
/// - Impulse reads
/// - Message reads
///
/// Uses device_id from DeviceRegistrationService for identification.
/// Deduplicates within session to avoid spam.
class ContentInteractionService {
  static final ContentInteractionService instance = ContentInteractionService._internal();
  ContentInteractionService._internal();

  static const _table = 'content_interactions';

  /// Track which content has been tracked this session to avoid duplicates
  final Set<String> _trackedThisSession = {};

  /// Track a content interaction.
  ///
  /// Only tracks the first interaction per content per session.
  /// Errors are logged but never thrown to prevent app crashes.
  Future<void> trackInteraction({
    required String contentId,
    required String contentType,
    String? title,
  }) async {
    // Deduplicate within session
    final key = '${contentType}_$contentId';
    if (_trackedThisSession.contains(key)) {
      return;
    }
    _trackedThisSession.add(key);

    try {
      final deviceId = DeviceRegistrationService.instance.deviceId;
      final platform = _platform;
      final appVersion = await _getAppVersion();

      await Supabase.instance.client.from(_table).insert({
        'device_id': deviceId,
        'content_type': contentType,
        'content_id': contentId,
        'content_title': title,
        'platform': platform,
        'app_version': appVersion,
      });

      debugPrint('[ContentInteraction] Tracked $contentType: $contentId');
    } catch (e) {
      debugPrint('[ContentInteraction] Error tracking interaction: $e');
      // Don't throw - tracking should never break the app
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
      debugPrint('[ContentInteraction] Error getting app version: $e');
      return 'unknown';
    }
  }

  /// Clear session tracking (useful for testing)
  void clearSessionTracking() {
    _trackedThisSession.clear();
  }
}
