import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/config/app_theme.dart';
import 'package:jugendkompass_app/presentation/navigation/bottom_nav_screen.dart';
import 'package:jugendkompass_app/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/domain/providers/theme_provider.dart';
import 'package:jugendkompass_app/core/services/notification_service.dart';
import 'package:jugendkompass_app/domain/providers/verse_provider.dart';
import 'package:jugendkompass_app/data/services/media_notification_service.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    // Initialize and schedule notifications once on app startup
    Future.microtask(() => _initializeNotifications(ref));

    return MaterialApp(
      title: 'Jugendkompass',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
            return const BottomNavScreen();
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
