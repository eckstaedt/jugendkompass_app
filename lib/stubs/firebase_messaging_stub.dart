// Web stub for firebase_messaging - not used on web platform
class FirebaseMessaging {
  static Future<void> onBackgroundMessage(dynamic handler) async {
    // No-op on web
  }
}

// Stub handler
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  // No-op on web
}
