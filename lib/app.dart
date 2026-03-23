import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/config/app_theme.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/presentation/navigation/bottom_nav_screen.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart';
import 'package:jugendkompass_app/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/domain/providers/theme_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/core/services/notification_service.dart';
import 'package:jugendkompass_app/domain/providers/verse_provider.dart';
import 'package:jugendkompass_app/data/services/media_notification_service.dart';

class App extends ConsumerWidget {
  const App({super.key});

  // Single observer instance lives with the App widget
  static final _routeObserver = FullPlayerRouteObserver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);
    
    // Initialize and schedule notifications once on app startup
    Future.microtask(() => _initializeNotifications(ref));

    return MaterialApp(
      title: 'Jugendkompass',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: language.locale,
      supportedLocales: AppLanguage.values.map((lang) => lang.locale).toList(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      navigatorObservers: [_routeObserver],
      builder: (context, child) {
        return MiniPlayerOverlay(
          routeObserver: _routeObserver,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: FutureBuilder<bool>(
        future: Future.value(
          UserPreferencesService.instance.hasCompletedOnboarding(),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final hasCompletedOnboarding = snapshot.data ?? false;

          if (hasCompletedOnboarding) {
            // Use a key that changes with language to force rebuild
            return BottomNavScreen(key: ValueKey(language));
          }

          return const OnboardingScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  /// Initialize notifications and schedule the daily verse notification
  /// Called once per app startup via Future.microtask to avoid blocking UI
  Future<void> _initializeNotifications(WidgetRef ref) async {
    try {
      // Initialize regular notifications for verses
      final notificationService = NotificationService();
      
      // Initialize the notification service
      await notificationService.init();
      
      // Request permissions
      await notificationService.requestPermission();
      
      // Initialize media notification service for Lock Screen controls
      final mediaNotificationService = MediaNotificationService();
      await mediaNotificationService.init();
      
      // Fetch today's verse using the existing provider
      final verseAsync = ref.read(dailyVerseProvider);
      
      // Schedule notification when verse is ready
      verseAsync.whenData((verse) {
        if (verse != null) {
          notificationService.scheduleDailyVerseNotification(
            verseText: verse.verse,
            reference: verse.reference,
          );
        }
      });
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }
}
