import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jugendkompass_app/app.dart';
import 'package:jugendkompass_app/core/config/env_config.dart';
import 'package:jugendkompass_app/core/services/image_cache_service.dart';
import 'package:jugendkompass_app/data/services/supabase_service.dart';
import 'package:jugendkompass_app/data/services/favorites_service.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/data/services/media_notification_service.dart';
import 'package:jugendkompass_app/data/services/audio_service.dart';
import 'package:jugendkompass_app/data/services/web_audio_controller.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Notification callback handler
void _onNotificationAction(NotificationResponse response) {
  final action = response.actionId;
  final audioService = AudioService.instance;

  switch (action) {
    case 'action_play':
      audioService.resume();
      break;
    case 'action_pause':
      audioService.pause();
      break;
    case 'action_skip_forward':
      audioService.skipForward(10);
      break;
    case 'action_skip_backward':
      audioService.skipBackward(10);
      break;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for German locale
  await initializeDateFormatting('de_DE', null);

  // Load environment variables
  await EnvConfig.load();

  // Initialize image caching
  ImageCacheConfig.configure();

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize User Preferences Service
  await UserPreferencesService.instance.init();

  // Initialize Favorites Service
  await FavoritesService.instance.initialize();

  // Initialize Media Notification Service
  final mediaNotificationService = MediaNotificationService();
  await mediaNotificationService.init();
  
  // Set notification action callback
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: _onNotificationAction,
  );

  // Initialize Web Audio Controller for browser media controls
  WebAudioController().init();

  runApp(const ProviderScope(child: App()));
}
