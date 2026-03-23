import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/widgets/mini_player_bar.dart';

/// Route name used when pushing [FullPlayerScreen] so the observer can
/// identify it without importing the screen (avoids circular imports).
const kFullPlayerRouteName = '/full_player';

/// A [NavigatorObserver] that tracks whether [FullPlayerScreen] is currently
/// on top of the navigation stack. Notifies a [ValueNotifier] so the overlay
/// can react without Riverpod.
class FullPlayerRouteObserver extends NavigatorObserver {
  final ValueNotifier<bool> fullPlayerActive = ValueNotifier(false);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == kFullPlayerRouteName) {
      fullPlayerActive.value = true;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route.settings.name == kFullPlayerRouteName) {
      fullPlayerActive.value = false;
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route.settings.name == kFullPlayerRouteName) {
      fullPlayerActive.value = false;
    }
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
  }
}

/// Wraps the entire app's widget tree (via MaterialApp.builder) and shows the
/// [MiniPlayerBar] persistently at the bottom of the screen above all routes,
/// unless [FullPlayerScreen] is currently active.
class MiniPlayerOverlay extends ConsumerStatefulWidget {
  const MiniPlayerOverlay({
    super.key,
    required this.child,
    required this.routeObserver,
  });

  final Widget child;
  final FullPlayerRouteObserver routeObserver;

  @override
  ConsumerState<MiniPlayerOverlay> createState() => _MiniPlayerOverlayState();
}

class _MiniPlayerOverlayState extends ConsumerState<MiniPlayerOverlay> {
  @override
  void initState() {
    super.initState();
    widget.routeObserver.fullPlayerActive.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    widget.routeObserver.fullPlayerActive.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentAudio = ref.watch(currentAudioProvider);
    final isFullPlayerActive = widget.routeObserver.fullPlayerActive.value;

    final showMiniPlayer = currentAudio != null && !isFullPlayerActive;

    // When the mini player is visible, add extra bottom padding to the child
    // so content is not hidden behind the bar (~96 px including safe area inset).
    const miniPlayerHeight = 96.0;
    final child = showMiniPlayer
        ? MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(context).padding.copyWith(
                    bottom: MediaQuery.of(context).padding.bottom +
                        miniPlayerHeight,
                  ),
            ),
            child: widget.child,
          )
        : widget.child;

    return Stack(
      children: [
        child,
        if (showMiniPlayer)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayerBar(audio: currentAudio),
          ),
      ],
    );
  }
}
