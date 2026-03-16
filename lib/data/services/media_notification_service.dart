import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service für Lock Screen Media Controls (Android)
class MediaNotificationService {
  static final MediaNotificationService _instance = MediaNotificationService._internal();
  
  factory MediaNotificationService() {
    return _instance;
  }

  MediaNotificationService._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  static const int _notificationId = 1;
  static const String _channelId = 'media_playback_channel';

  Future<void> init() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Android setup
    const androidSettings = AndroidInitializationSettings('mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Create notification channel
    const channel = AndroidNotificationChannel(
      'media_playback_channel',
      'Audio Playback',
      description: 'Notifications for audio and podcast playback',
      importance: Importance.low,
    );

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> showPlaybackNotification({
    required AudioModel audio,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
  }) async {
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Audio Playback',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: duration.inSeconds,
          progress: position.inSeconds,
          ongoing: isPlaying,
          autoCancel: false,
          actions: [
            const AndroidNotificationAction(
              'action_skip_previous',
              'Zurück',
            ),
            AndroidNotificationAction(
              isPlaying ? 'action_pause' : 'action_play',
              isPlaying ? 'Pause' : 'Play',
            ),
            const AndroidNotificationAction(
              'action_skip_next',
              'Weiter',
            ),
          ],
        ),
      );

      final title = audio.title ?? 'Podcast';
      final artist = audio.artist ?? audio.post?.title ?? 'Jugendkompass';

      await _notificationsPlugin.show(
        _notificationId,
        title,
        artist,
        details,
        payload: audio.id,
      );
    } catch (e) {
      print('Error showing playback notification: $e');
    }
  }

  Future<void> hidePlaybackNotification() async {
    await _notificationsPlugin.cancel(_notificationId);
  }
}




