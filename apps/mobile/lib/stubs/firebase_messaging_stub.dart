// Web stub for firebase_messaging - not used on web platform

enum AuthorizationStatus {
  authorized,
  denied,
  notDetermined,
  provisional,
}

class NotificationSettings {
  final AuthorizationStatus authorizationStatus;
  NotificationSettings({this.authorizationStatus = AuthorizationStatus.denied});
}

class FirebaseMessaging {
  static final FirebaseMessaging _instance = FirebaseMessaging._();
  FirebaseMessaging._();

  static FirebaseMessaging get instance => _instance;

  static Future<void> onBackgroundMessage(dynamic handler) async {
    // No-op on web
  }

  Future<NotificationSettings> getNotificationSettings() async {
    return NotificationSettings();
  }

  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
    bool provisional = false,
  }) async {
    return NotificationSettings();
  }
}
