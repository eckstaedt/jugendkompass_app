import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/config/app_theme.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/presentation/navigation/bottom_nav_screen.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart'
    show FullPlayerRouteObserver, MiniPlayerOverlayHost;
import 'package:jugendkompass_app/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/domain/providers/theme_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/bottom_nav_provider.dart';
import 'package:jugendkompass_app/core/services/notification_service.dart';
import 'package:jugendkompass_app/domain/providers/verse_provider.dart';
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
    widget.routeObserver.hideNavActive.addListener(_onHideNavChange);
    widget.routeObserver.onRoutePushed = _onRoutePushed;
    widget.routeObserver.onRoutePopped = _onRoutePopped;
  }

  @override
  void dispose() {
    widget.routeObserver.fullPlayerActive.removeListener(_onFullPlayerChange);
    widget.routeObserver.hideNavActive.removeListener(_onHideNavChange);
    widget.routeObserver.onRoutePushed = null;
    widget.routeObserver.onRoutePopped = null;
    super.dispose();
  }

  void _onFullPlayerChange() {
    if (mounted) setState(() {});
  }

  void _onHideNavChange() {
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
    final hideNav = widget.routeObserver.hideNavActive.value;
    final navBarVisible = ref.watch(navBarVisibleProvider);
    final navBarOffset = ref.watch(miniPlayerBottomOffsetProvider);
    final showNav = navBarVisible && !hideNav;
    final showBar = currentAudio != null && !isFullPlayer && showNav;
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    // Mini bar sits above the navbar when it is visible.
    final miniBarBottom = showNav
        ? (_routeDepth > 0
            ? safeBottom + BottomNavScreen.navBarHeight
            : navBarOffset)
        : safeBottom;

    return Stack(
      children: [
        widget.child,

        // ── Persistent navbar ───────────────────────────────────────────────
        if (showNav)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            // Material is required so InkWell/ripples work inside the overlay
            // Stack (MaterialApp.builder has no Material ancestor of its own).
            child: Material(
              type: MaterialType.transparency,
              child: _PersistentNavBar(
                selectedIndex: selectedIndex,
                onItemTapped: (i) {
                  // Pop back to root if we're on a pushed detail screen.
                  if (_routeDepth > 0) {
                    widget.navigatorKey.currentState
                        ?.popUntil((route) => route.isFirst);
                  }
                  ref.read(bottomNavIndexProvider.notifier).setIndex(i);
                },
              ),
            ),
          ),

        // ── Mini player bar (above the navbar) ─────────────────────────────
        if (showBar)
          Positioned(
            left: 0,
            right: 0,
            bottom: miniBarBottom,
            child: Material(
              type: MaterialType.transparency,
              child: MiniPlayerBar(
                audio: currentAudio,
                navigatorKey: widget.navigatorKey,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Persistent navbar ────────────────────────────────────────────────────────
//
// Drawn by the MaterialApp.builder overlay so it appears on EVERY route.
// Hidden only when kFullPlayerRouteName or kVideoPlayerRouteName is active.

class _PersistentNavBar extends ConsumerWidget {
  const _PersistentNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      height: 60,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusNavBar),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: DesignTokens.glassBlurSigma,
            sigmaY: DesignTokens.glassBlurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: DesignTokens.getGlassBackground(brightness, 0.14),
              borderRadius: BorderRadius.circular(DesignTokens.radiusNavBar),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [DesignTokens.shadowGlass],
            ),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _item(context, Icons.home_outlined, Icons.home, 'Home', 0),
                    _item(context, Icons.explore_outlined, Icons.explore,
                        'Kiosk', 1),
                    _item(
                        context, Icons.mic_outlined, Icons.mic, 'Podcast', 2),
                    _item(context, Icons.video_library_outlined,
                        Icons.video_library, 'Videos', 3),
                    _item(context, Icons.menu, Icons.menu, 'Menü', 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, IconData selectedIcon,
      String label, int index) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onItemTapped(index),
        borderRadius: BorderRadius.circular(16),
        splashColor: DesignTokens.primaryRed.withValues(alpha: 0.1),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? DesignTokens.primaryRed
                      : DesignTokens.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 5 : 0,
                  height: isSelected ? 5 : 0,
                  decoration: const BoxDecoration(
                    color: DesignTokens.primaryRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
