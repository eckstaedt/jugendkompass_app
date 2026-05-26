import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/core/services/device_registration_service.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/core/services/deep_link_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _listenersSetup = false;

  /// Local notifications plugin for showing foreground messages.
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Stored initial message from cold start (before callback is set)
  RemoteMessage? _pendingInitialMessage;

  /// Callback for handling notification tap navigation.
  /// Set this from the app's root widget to enable deep linking.
  Future<void> Function(Map<String, dynamic> data)? _onNotificationTap;

  set onNotificationTap(Future<void> Function(Map<String, dynamic> data)? callback) {
    _onNotificationTap = callback;
    debugPrint('[FCM] onNotificationTap callback set');

    // Process any pending initial message from cold start
    if (_pendingInitialMessage != null && callback != null) {
      debugPrint('[FCM] Processing pending initial message');
      final data = _pendingInitialMessage!.data;
      if (data.isNotEmpty) {
        callback(data);
      }
      _pendingInitialMessage = null;
    }
  }

  Future<void> Function(Map<String, dynamic> data)? get onNotificationTap => _onNotificationTap;

  /// Initialize FCM without requesting permissions.
  /// Only sets up listeners for notification taps and checks if already authorized.
  /// Call this at app startup.
  Future<void> initWithoutPermissionRequest() async {
    if (_listenersSetup) return;

    try {
      // Initialize local notifications for foreground display
      try {
        await _initLocalNotifications();
      } catch (e) {
        debugPrint('[FCM] Could not init local notifications: $e');
      }

      // Set up notification tap handlers (works even without permission)
      _setupNotificationTapHandlers();

      // Check if we already have permission
      final settings = await _messaging.getNotificationSettings();
      debugPrint('[FCM] Current permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Already authorized, get token and set up listeners
        await _setupAfterPermissionGranted();
      }

      _listenersSetup = true;
    } catch (e) {
      debugPrint('[FCM] Error during initWithoutPermissionRequest: $e');
    }
  }

  /// Initialize FCM with permission request.
  /// This requests permission from the user and should only be called
  /// when the user explicitly enables notifications.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Ensure listeners are set up
      if (!_listenersSetup) {
        await initWithoutPermissionRequest();
      }

      // Request Android 13+ notification permission
      if (!kIsWeb && Platform.isAndroid) {
        try {
          await _requestAndroidNotificationPermission();
        } catch (e) {
          debugPrint('[FCM] Could not request Android permission: $e');
        }
      }

      // Request permission (iOS shows a system dialog)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] Permission status after request: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _setupAfterPermissionGranted();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[FCM] Error during init: $e');
    }
  }

  /// Set up FCM after permission is granted (get token, listen for messages)
  Future<void> _setupAfterPermissionGranted() async {
    // Get the FCM token
    await _getAndStoreToken();

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      _storeToken(newToken);
    });

    // Handle foreground messages — show as local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Set up handlers for notification taps from different app states.
  void _setupNotificationTapHandlers() {
    debugPrint('[FCM] Setting up notification tap handlers');

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundNotificationTap);

    // Handle notification tap when app was terminated (cold start)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      debugPrint('[FCM] getInitialMessage returned: ${message?.messageId}');
      if (message != null) {
        if (_onNotificationTap != null) {
          // Callback already set, process immediately
          _handleBackgroundNotificationTap(message);
        } else {
          // Store for later when callback is set
          debugPrint('[FCM] Storing initial message for later processing');
          _pendingInitialMessage = message;
        }
      }
    });
  }

  /// Handle notification tap from background or terminated state.
  void _handleBackgroundNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.messageId}');
    debugPrint('[FCM] Message data keys: ${message.data.keys.toList()}');
    debugPrint('[FCM] Full notification data: ${message.data}');

    final data = message.data;
    if (data.isNotEmpty && _onNotificationTap != null) {
      debugPrint('[FCM] Calling onNotificationTap callback with data: $data');
      _onNotificationTap!(data);
    } else {
      debugPrint('[FCM] Cannot process tap: data.isEmpty=${data.isEmpty}, callback=${_onNotificationTap != null}');
      if (data.isEmpty) {
        debugPrint('[FCM] WARNING: Notification data is empty! Check FCM payload.');
      }
    }
  }

  /// Handle notification tap from local notification (foreground).
  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] Local notification tapped: ${response.payload}');
    // Payload contains the serialized data from the notification
    if (response.payload != null && _onNotificationTap != null) {
      try {
        // Parse the payload - we'll store the data as JSON string
        final data = <String, dynamic>{};
        final parts = response.payload!.split('|');
        if (parts.length >= 2) {
          data['contentType'] = parts[0];
          data['contentId'] = parts[1];
        }
        debugPrint('[FCM] Parsed local notification data: $data');
        _onNotificationTap!(data);
      } catch (e) {
        debugPrint('[FCM] Error parsing notification payload: $e');
      }
    } else {
      debugPrint('[FCM] Cannot process local tap: payload=${response.payload}, callback=${_onNotificationTap != null}');
    }
  }

  /// Set up local notifications so we can display foreground messages.
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // FCM handles this
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create Android notification channel with image support
    const androidChannel = AndroidNotificationChannel(
      'push_notifications',
      'Push-Benachrichtigungen',
      description: 'Benachrichtigungen für neue Beiträge',
      importance: Importance.high,
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Request notification permission on Android 13+ (API 33+).
  Future<void> _requestAndroidNotificationPermission() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('[FCM] Android notification permission granted: $granted');
    }
  }

  /// Get the current FCM token and store it in Supabase.
  /// Retries on SERVICE_NOT_AVAILABLE errors (common on Android).
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

      // Retry logic for Android SERVICE_NOT_AVAILABLE errors
      String? token;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          token = await _messaging.getToken();
          if (token != null) break;
        } catch (e) {
          final errorStr = e.toString();
          if (errorStr.contains('SERVICE_NOT_AVAILABLE') && attempt < 3) {
            debugPrint('[FCM] SERVICE_NOT_AVAILABLE, retry $attempt/3 in ${attempt * 2}s...');
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          rethrow;
        }
      }

      if (token != null) {
        debugPrint('[FCM] Token obtained: ${token.substring(0, 20)}...');
        await _storeToken(token);
      } else {
        debugPrint('[FCM] Token is null after retries');
      }
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  /// Store the FCM token in Supabase `device_tokens` table.
  Future<void> _storeToken(String fcmToken) async {
    try {
      final deviceId = DeviceRegistrationService.instance.deviceId;
      final language = UserPreferencesService.instance.getLanguage();
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

    // Create payload string for tap handling
    final data = message.data;
    final payload = data.containsKey('contentType') && data.containsKey('contentId')
        ? '${data['contentType']}|${data['contentId']}'
        : null;

    // Get image URL from notification (supports both platforms)
    String? imageUrl;
    if (notification.android?.imageUrl != null) {
      imageUrl = notification.android!.imageUrl;
    } else if (notification.apple?.imageUrl != null) {
      imageUrl = notification.apple!.imageUrl;
    }

    debugPrint('[FCM] Image URL: $imageUrl');

    // Show notification with image if available
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          attachments: imageUrl != null
              ? [DarwinNotificationAttachment(imageUrl)]
              : null,
        ),
        android: AndroidNotificationDetails(
          'push_notifications',
          'Push-Benachrichtigungen',
          channelDescription: 'Benachrichtigungen für neue Beiträge',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: imageUrl != null
              ? BigPictureStyleInformation(
                  DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // placeholder while loading
                  largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
                  contentTitle: notification.title,
                  summaryText: notification.body,
                )
              : null,
        ),
      ),
      payload: payload,
    );
  }
}

/// Top-level function to handle background messages.
///
/// Must be a top-level function (not a class method).
/// Firebase automatically shows notifications when app is in background if the
/// message includes a notification payload, so we don't need to manually show them.
/// This handler is for data processing only.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');

  // Note: Firebase automatically displays notifications with notification payload
  // when the app is in background or terminated. We don't need to show them manually.
  // This handler is just for processing data or performing background tasks.

  final notification = message.notification;
  final data = message.data;

  debugPrint('[FCM] Background notification: ${notification?.title}');
  debugPrint('[FCM] Background data: $data');

  // Any background data processing can be done here
  // Do NOT manually show the notification - Firebase already did that
}
