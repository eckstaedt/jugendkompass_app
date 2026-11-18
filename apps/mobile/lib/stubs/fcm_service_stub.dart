// Web stub for fcm_service - not used on web platform

// Stub handler for Firebase background messages
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  // No-op on web
}

/// No-op stub for FCMService on web.
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  Future<void> init() async {}

  Future<void> initWithoutPermissionRequest() async {}

  // ignore: avoid_setters_without_getters
  set onNotificationTap(Future<void> Function(Map<String, dynamic>) handler) {}
}
