import 'package:flutter/material.dart';

/// Custom Page Route für Fade-In/Out Animationen
class FadePageRoute<T> extends PageRoute<T> {
  FadePageRoute({
    required this.builder,
    this.fadeDuration = const Duration(milliseconds: 300),
    super.settings,
  });

  final WidgetBuilder builder;
  final Duration fadeDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => fadeDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
