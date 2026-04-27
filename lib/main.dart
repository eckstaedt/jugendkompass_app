import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jugendkompass_app/app.dart';
import 'package:jugendkompass_app/core/config/env_config.dart';
import 'package:jugendkompass_app/core/services/image_cache_service.dart';
import 'package:jugendkompass_app/data/services/supabase_service.dart';
import 'package:jugendkompass_app/data/services/favorites_service.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/data/services/web_audio_controller.dart';
import 'package:jugendkompass_app/core/services/home_widget_service.dart'
    if (dart.library.html) 'package:jugendkompass_app/stubs/home_widget_service_stub.dart';
import 'package:jugendkompass_app/core/services/local_verse_notification_service.dart';

// Mobile-only imports
import 'package:firebase_core/firebase_core.dart'
    if (dart.library.html) 'package:jugendkompass_app/stubs/firebase_core_stub.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.html) 'package:jugendkompass_app/stubs/firebase_messaging_stub.dart';
import 'package:jugendkompass_app/firebase_options.dart'
    if (dart.library.html) 'package:jugendkompass_app/stubs/firebase_options_stub.dart';
import 'package:jugendkompass_app/core/services/fcm_service.dart'
    if (dart.library.html) 'package:jugendkompass_app/stubs/fcm_service_stub.dart';
import 'package:just_audio_background/just_audio_background.dart'
    if (dart.library.html) 'package:jugendkompass_app/stubs/just_audio_background_stub.dart';

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

  // Initialize Firebase (not configured for web yet)
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Initialize User Preferences Service
  await UserPreferencesService.instance.init();

  // Initialize Favorites Service
  await FavoritesService.instance.initialize();

  // Initialize Home Widget Service (iOS only, no-op on web)
  await HomeWidgetService.initialize();

  // Initialize local verse notification service (mobile only)
  await LocalVerseNotificationService.instance.init();

  // Schedule verse notification if enabled
  {
    final prefs = UserPreferencesService.instance;
    if (prefs.getNotificationsEnabled() && prefs.getVerseNotificationsEnabled()) {
      await LocalVerseNotificationService.instance.scheduleDaily(
        prefs.getNotificationHour(),
        prefs.getNotificationMinute(),
        prefs.getTimezone(),
      );
    }
  }

  // Initialize just_audio_background (mobile only) — this powers the native lock screen
  // controls (play/pause, skip ±10s, artwork, title) on iOS and Android.
  if (!kIsWeb) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.jugendkompass.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: const Color(0xFF2B6CB0),
    );
  }

  // Initialize Web Audio Controller for browser media controls (web only)
  if (kIsWeb) {
    await WebAudioController().init();
  }

  runApp(const ProviderScope(child: App()));
}
