import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/config/app_theme.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/presentation/navigation/bottom_nav_screen.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart'
    show FullPlayerRouteObserver, MiniPlayerOverlayHost;
import 'package:jugendkompass_app/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/domain/providers/theme_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/core/services/notification_service.dart';
import 'package:jugendkompass_app/domain/providers/verse_provider.dart';
import 'package:jugendkompass_app/data/services/media_notification_service.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/widgets/mini_player_bar.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  final _routeObserver = FullPlayerRouteObserver();
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);

    Future.microtask(() => _initializeNotifications());

    return MaterialApp(
      title: 'Jugendkompass',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: language.locale,
      supportedLocales: AppLanguage.values.map((lang) => lang.locale).toList(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      navigatorKey: _navigatorKey,
      navigatorObservers: [_routeObserver],
      // builder wraps EVERY route including pushed ones, so the mini player
      // is always visible regardless of navigation depth.
      builder: (context, child) {
        return _MiniPlayerScaffold(
          routeObserver: _routeObserver,
          navigatorKey: _navigatorKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: MiniPlayerOverlayHost(
        observer: _routeObserver,
        navigatorKey: _navigatorKey,
        child: FutureBuilder<bool>(
          future: Future.value(
            UserPreferencesService.instance.hasCompletedOnboarding(),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final hasCompletedOnboarding = snapshot.data ?? false;
            return hasCompletedOnboarding
                ? BottomNavScreen(key: ValueKey(language))
                : const OnboardingScreen();
          },
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  /// Initialize notifications and schedule the daily verse notification
  /// Called once per app startup via Future.microtask to avoid blocking UI
  Future<void> _initializeNotifications() async {
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

// ─── Persistent mini-player wrapper ─────────────────────────────────────────
//
// Placed inside MaterialApp.builder so it wraps EVERY route (including
// pushed routes like PostDetailScreen).  It watches currentAudioProvider and
// shows / hides the MiniPlayerBar at the bottom of the screen without
// affecting the layout of the route underneath.

class _MiniPlayerScaffold extends ConsumerStatefulWidget {
  const _MiniPlayerScaffold({
    required this.child,
    required this.routeObserver,
    required this.navigatorKey,
  });

  final Widget child;
  final FullPlayerRouteObserver routeObserver;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  ConsumerState<_MiniPlayerScaffold> createState() =>
      _MiniPlayerScaffoldState();
}

class _MiniPlayerScaffoldState extends ConsumerState<_MiniPlayerScaffold> {
  // Tracks how many routes have been pushed on top of the root home widget.
  // When > 0, BottomNavScreen is NOT visible, so we use safe-area-only offset.
  int _routeDepth = 0;

  @override
  void initState() {
    super.initState();
    widget.routeObserver.fullPlayerActive.addListener(_onFullPlayerChange);
    widget.routeObserver.onRoutePushed = _onRoutePushed;
    widget.routeObserver.onRoutePopped = _onRoutePopped;
  }

  @override
  void dispose() {
    widget.routeObserver.fullPlayerActive.removeListener(_onFullPlayerChange);
    widget.routeObserver.onRoutePushed = null;
    widget.routeObserver.onRoutePopped = null;
    super.dispose();
  }

  void _onFullPlayerChange() {
    if (mounted) setState(() {});
  }

  void _onRoutePushed() {
    if (mounted) setState(() => _routeDepth++);
  }

  void _onRoutePopped() {
    if (mounted) setState(() => _routeDepth = (_routeDepth - 1).clamp(0, 999));
  }

  @override
  Widget build(BuildContext context) {
    final currentAudio = ref.watch(currentAudioProvider);
    final isFullPlayer = widget.routeObserver.fullPlayerActive.value;
    final navBarOffset = ref.watch(miniPlayerBottomOffsetProvider);
    final showBar = currentAudio != null && !isFullPlayer;

    // When a detail/sub route is pushed, BottomNavScreen is no longer in the
    // widget tree.  Use safe-area bottom inset only so the bar sits right at
    // the bottom edge of the screen.
    final bottomOffset = _routeDepth > 0
        ? MediaQuery.paddingOf(context).bottom
        : navBarOffset;

    return Stack(
      children: [
        widget.child,
        if (showBar)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomOffset,
            child: MiniPlayerBar(
              audio: currentAudio,
              navigatorKey: widget.navigatorKey,
            ),
          ),
      ],
    );
  }
}
