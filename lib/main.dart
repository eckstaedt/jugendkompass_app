import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:jugendkompass_app/firebase_options.dart';
import 'package:jugendkompass_app/core/services/fcm_service.dart';
import 'package:jugendkompass_app/app.dart';
import 'package:jugendkompass_app/core/config/env_config.dart';
import 'package:jugendkompass_app/core/services/image_cache_service.dart';
import 'package:jugendkompass_app/data/services/supabase_service.dart';
import 'package:jugendkompass_app/data/services/favorites_service.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/data/services/web_audio_controller.dart';
import 'package:jugendkompass_app/core/services/home_widget_service.dart';
import 'package:just_audio_background/just_audio_background.dart';

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

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize User Preferences Service
  await UserPreferencesService.instance.init();

  // Initialize Favorites Service
  await FavoritesService.instance.initialize();

  // Initialize Home Widget Service (iOS)
  await HomeWidgetService.initialize();

  // Initialize just_audio_background — this powers the native lock screen
  // controls (play/pause, skip ±10s, artwork, title) on iOS and Android.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.jugendkompass.audio',
    androidNotificationChannelName: 'Audio Playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
    notificationColor: const Color(0xFF2B6CB0),
  );

  // Initialize Web Audio Controller for browser media controls
  await WebAudioController().init();

  runApp(const ProviderScope(child: App()));
}
