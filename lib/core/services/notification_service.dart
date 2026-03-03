import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

/// Service for managing local notifications
/// 
/// Handles:
/// - Initialization of local notifications
/// - Permission requests
/// - Scheduling daily verse notifications at 07:00
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

  /// Initialize the notification service
  /// Must be called during app startup before using any notification features
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone database
    tzdata.initializeTimeZones();

    // Initialize platform-specific settings
    const androidSettings =
        AndroidInitializationSettings('app_icon');
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
    _isInitialized = true;
  }

  /// Request notification permissions from the user
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

  /// Schedule a daily verse notification at 07:00
  /// 
  /// [verseText]: The verse text to display
  /// [reference]: The bible reference (e.g., "John 3:16")
  /// 
  /// If current time is already past 07:00, schedules for next day
  Future<void> scheduleDailyVerseNotification({
    required String verseText,
    required String reference,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    const notificationId = 1;
    
    // Cancel existing notification to avoid duplicates
    await _notificationsPlugin.cancel(notificationId);

    try {
      // Get Berlin timezone (German app, assumed timezone)
      final berlin = tz.getLocation('Europe/Berlin');
      var scheduleTime = tz.TZDateTime(berlin, 
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        7, // 07:00
        0,
      );

      // If it's already past 07:00, schedule for next day
      if (scheduleTime.isBefore(tz.TZDateTime.now(berlin))) {
        scheduleTime = scheduleTime.add(const Duration(days: 1));
      }

      // Schedule with timezone-aware daily repetition
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Vers des Tages',
        '"$verseText"\n\n— $reference',
        scheduleTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'verse_channel',
            'Vers des Tages',
            channelDescription: 'Tägliche Benachrichtigung mit einem Bibelvers',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('Error scheduling daily verse notification: $e');
    }
  }

  /// Schedule a test notification for now + 1 minute
  /// 
  /// This is for testing purposes only and does not affect daily verse notifications
  /// The test notification uses a separate ID (999) to avoid conflicts
  Future<void> scheduleTestNotification() async {
    if (!_isInitialized) {
      await init();
    }

    const testNotificationId = 999;

    try {
      // Calculate time 1 minute from now
      final berlin = tz.getLocation('Europe/Berlin');
      final scheduleTime = tz.TZDateTime.now(berlin).add(const Duration(minutes: 1));

      // Schedule one-time notification (no daily repetition)
      await _notificationsPlugin.zonedSchedule(
        testNotificationId,
        '🧪 Test Benachrichtigung',
        'Wenn du das liest, funktioniert alles.',
        scheduleTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Benachrichtigungen',
            channelDescription: 'Einmalige Test-Benachrichtigungen',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // NO matchDateTimeComponents for test notification (one-time only)
      );
    } catch (e) {
      print('Error scheduling test notification: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAll() async {
    if (!_isInitialized) return;
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel a specific notification by ID
  Future<void> cancel(int id) async {
    if (!_isInitialized) return;
    await _notificationsPlugin.cancel(id);
  }
}
