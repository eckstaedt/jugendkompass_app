import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Custom Page Route.
/// On iOS: uses the native horizontal slide transition which includes the
/// system swipe-back gesture. On other platforms: uses a fade transition.
class FadePageRoute<T> extends MaterialPageRoute<T> {
  FadePageRoute({
    required super.builder,
    this.fadeDuration = const Duration(milliseconds: 300),
    super.settings,
  });

  final Duration fadeDuration;

  @override
  Duration get transitionDuration => fadeDuration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // On iOS: delegate to MaterialPageRoute which uses CupertinoPageTransitionsBuilder
    // – this gives us the native horizontal slide AND the swipe-back gesture for free.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return super.buildTransitions(context, animation, secondaryAnimation, child);
    }
    // On Android (and others): keep the original fade.
    return FadeTransition(opacity: animation, child: child);
  }
}
