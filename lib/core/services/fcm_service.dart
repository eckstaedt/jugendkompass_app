import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/core/services/device_registration_service.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';

/// Handles Firebase Cloud Messaging (FCM) for server-sent push notifications.
///
/// Responsibilities:
/// - Request push notification permissions
/// - Retrieve and store the FCM token in Supabase `device_tokens` table
/// - Listen for token refreshes
/// - Handle foreground notifications (show local notification)
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// Local notifications plugin for showing foreground messages.
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM: request permissions, get token, listen for refresh.
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize local notifications for foreground display
    await _initLocalNotifications();

    // Request permission (iOS shows a system dialog)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      '[FCM] Permission status: ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get the FCM token
      await _getAndStoreToken();

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        _storeToken(newToken);
      });

      // Handle foreground messages — show as local notification
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    }

    _isInitialized = true;
  }

  /// Set up local notifications so we can display foreground messages.
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('app_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // FCM handles this
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);
  }

  /// Get the current FCM token and store it in Supabase.
  Future<void> _getAndStoreToken() async {
    try {
      // On iOS, get the APNs token first
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken = await _messaging.getAPNSToken();
        debugPrint('[FCM] APNs token: ${apnsToken != null ? "obtained" : "null"}');
        if (apnsToken == null) {
          // APNs token not yet available, wait and retry
          for (int i = 0; i < 3; i++) {
            await Future.delayed(const Duration(seconds: 2));
            apnsToken = await _messaging.getAPNSToken();
            if (apnsToken != null) break;
          }
          if (apnsToken == null) {
            debugPrint('[FCM] APNs token still null after retries');
            return;
          }
        }
      }

      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Token obtained: ${token.substring(0, 20)}...');
        await _storeToken(token);
      } else {
        debugPrint('[FCM] Token is null');
      }
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  /// Store the FCM token in Supabase `device_tokens` table.
  Future<void> _storeToken(String fcmToken) async {
    try {
      final deviceId = DeviceRegistrationService.instance.deviceId;
      final language = await UserPreferencesService.instance.getLanguage();
      final supabase = Supabase.instance.client;

      await supabase.from('device_tokens').upsert(
        {
          'device_id': deviceId,
          'fcm_token': fcmToken,
          'language': language,
        },
        onConflict: 'device_id',
      );

      debugPrint('[FCM] Token stored in Supabase for device: $deviceId');
    } catch (e) {
      debugPrint('[FCM] Error storing token: $e');
    }
  }

  /// Handle messages received while the app is in the foreground.
  ///
  /// Firebase doesn't automatically show notifications when the app is in
  /// the foreground, so we show them manually via flutter_local_notifications.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'push_notifications',
          'Push-Benachrichtigungen',
          channelDescription: 'Benachrichtigungen für neue Beiträge',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

/// Top-level function to handle background messages.
///
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}
