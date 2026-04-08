import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for managing notification permissions.
///
/// All actual push notifications are sent from the server via APNs / FCM.
/// This service only handles:
/// - Initialising the notification plugin (needed to receive server pushes)
/// - Requesting user permission on iOS
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  late final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  /// Initialise the plugin so the OS can deliver remote notifications.
  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('app_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // iOS: request permission to show alerts / badges / sounds
    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _isInitialized = true;
  }

  /// Request notification permissions from the user.
  Future<bool> requestPermission() async {
    final granted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
    return granted;
  }
}
