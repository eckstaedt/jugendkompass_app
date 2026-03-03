import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/services/notification_service.dart';

/// Provider to manage notification initialization and scheduling
/// 
/// This provider ensures notifications are set up once per app lifecycle
/// and the daily verse notification is scheduled without rebuilds
final notificationServiceProvider = FutureProvider<void>((ref) async {
  final notificationService = NotificationService();
  
  // Initialize the notification service
  await notificationService.init();
});

/// Provider to schedule the daily verse notification
/// 
/// Call this after fetching today's verse to schedule it for 07:00
/// This should only be called once per app startup
Future<void> scheduleDailyVerseNotification(
  String verseText,
  String reference,
) async {
  final notificationService = NotificationService();
  await notificationService.scheduleDailyVerseNotification(
    verseText: verseText,
    reference: reference,
  );
}

/// TEST ONLY: Schedule a test notification 1 minute from now
/// 
/// This is for debugging and testing purposes.
/// The test notification uses a separate ID (999) and does not affect
/// the daily verse notification system.
Future<void> scheduleTestNotificationForDebug() async {
  final notificationService = NotificationService();
  await notificationService.scheduleTestNotification();
}
