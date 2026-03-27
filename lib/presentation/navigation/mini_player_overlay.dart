import 'package:flutter/material.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';

/// Route name used when pushing [FullPlayerScreen] so the observer can
/// identify it without importing the screen (avoids circular imports).
const kFullPlayerRouteName = '/full_player';

/// Route name used when pushing [VideoPlayerScreen].
const kVideoPlayerRouteName = '/video_player';

/// Route name used for the onboarding / name-input screen.
const kOnboardingRouteName = '/onboarding';

/// Route name used for [EditionDetailScreen] (inside an Ausgabe).
const kEditionDetailRouteName = '/edition_detail';

/// Route names where the navbar and mini bar should be hidden.
const _kHideNavRoutes = {
  kFullPlayerRouteName,
  kVideoPlayerRouteName,
  kOnboardingRouteName,
  kEditionDetailRouteName,
};

/// A [NavigatorObserver] that tracks whether [FullPlayerScreen] is currently
/// on top of the navigation stack.
class FullPlayerRouteObserver extends NavigatorObserver {
  final ValueNotifier<bool> fullPlayerActive = ValueNotifier(false);
  /// True whenever a route that should hide the navbar/mini-bar is on top.
  final ValueNotifier<bool> hideNavActive = ValueNotifier(false);
  // Called whenever any route is pushed (used to reset the bottom offset
  // for pushed detail screens where the bottom navbar is not visible).
  VoidCallback? onRoutePushed;
  VoidCallback? onRoutePopped;

  void _updateHideNav(String? routeName) {
    hideNavActive.value = _kHideNavRoutes.contains(routeName);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == kFullPlayerRouteName) {
      fullPlayerActive.value = true;
    }
    _updateHideNav(route.settings.name);
    // Notify so app.dart can reset the bottom offset.
    if (previousRoute != null) onRoutePushed?.call();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route.settings.name == kFullPlayerRouteName) {
      fullPlayerActive.value = false;
    }
    _updateHideNav(previousRoute?.settings.name);
    onRoutePopped?.call();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route.settings.name == kFullPlayerRouteName) {
      fullPlayerActive.value = false;
    }
    _updateHideNav(previousRoute?.settings.name);
    onRoutePopped?.call();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute?.settings.name == kFullPlayerRouteName) {
      fullPlayerActive.value = false;
    }
    if (newRoute?.settings.name == kFullPlayerRouteName) {
      fullPlayerActive.value = true;
    }
    _updateHideNav(newRoute?.settings.name);
  }
}

/// Global notifier for the currently playing audio.
/// Set this whenever audio starts anywhere in the app.
/// Setting to null hides the mini bar.
///
/// NOTE: The mini player is now embedded directly in [BottomNavScreen]'s
/// bottomNavigationBar column (above the nav pill). This notifier is kept
/// for backward compatibility so existing call-sites that set
/// [currentAudioNotifier.value] still work — but the visible bar is driven
/// by [currentAudioProvider] (Riverpod) instead.
final currentAudioNotifier = ValueNotifier<AudioModel?>(null);

/// Simple passthrough host. Kept so [app.dart] doesn't need changes.
class MiniPlayerOverlayHost extends StatelessWidget {
  const MiniPlayerOverlayHost({
    super.key,
    required this.child,
    required this.observer,
    required this.navigatorKey,
  });

  final Widget child;
  final FullPlayerRouteObserver observer;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) => child;
}
