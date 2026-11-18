import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

/// Swipe left/right to the next/previous item (impulses, articles of an
/// edition). While dragging, an arrow appears at the edge and a ring around
/// it fills up; when the ring is full, letting go opens the neighbour.
/// The first time ([hintKey]) the content does a short "fake" swipe as hint.
class SwipePager extends StatefulWidget {
  const SwipePager({
    super.key,
    required this.child,
    this.onNext,
    this.onPrevious,
    this.hintKey,
  });

  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final String? hintKey;

  @override
  State<SwipePager> createState() => _SwipePagerState();
}

class _SwipePagerState extends State<SwipePager> with SingleTickerProviderStateMixin {
  static const _threshold = 110.0;
  double _dx = 0;
  bool _armed = false;
  late final AnimationController _back =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
        ..addListener(() => setState(() => _dx = _from * (1 - Curves.easeOut.transform(_back.value))));
  double _from = 0;

  @override
  void initState() {
    super.initState();
    if (widget.hintKey != null && widget.onNext != null) _maybeHint();
  }

  Future<void> _maybeHint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'swipe_hint_${widget.hintKey}';
      if (prefs.getBool(key) ?? false) return;
      await prefs.setBool(key, true);
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      // Pull the content to the left as if swiping, then let it spring back.
      for (var i = 1; i <= 12; i++) {
        await Future.delayed(const Duration(milliseconds: 16));
        if (!mounted) return;
        setState(() => _dx = -_threshold * 0.6 * Curves.easeOut.transform(i / 12));
      }
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      _from = _dx;
      _back.forward(from: 0);
    } catch (_) {}
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails d) {
    _back.stop();
    var dx = _dx + d.delta.dx;
    if (dx < 0 && widget.onNext == null) dx = 0;
    if (dx > 0 && widget.onPrevious == null) dx = 0;
    final armed = dx.abs() >= _threshold;
    if (armed && !_armed) HapticFeedback.lightImpact();
    setState(() {
      _dx = dx.clamp(-_threshold * 1.3, _threshold * 1.3);
      _armed = armed;
    });
  }

  void _end(DragEndDetails d) {
    final go = _dx.abs() >= _threshold;
    final next = _dx < 0;
    if (go) {
      HapticFeedback.mediumImpact();
      (next ? widget.onNext : widget.onPrevious)?.call();
    }
    _armed = false;
    _from = _dx;
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dx.abs() / _threshold).clamp(0.0, 1.0);
    final next = _dx < 0;
    final brightness = Theme.of(context).brightness;
    final color = brightness == Brightness.dark ? DesignTokens.primaryRedOnDark : DesignTokens.primaryRed;
    return GestureDetector(
      onHorizontalDragUpdate: _update,
      onHorizontalDragEnd: _end,
      child: Stack(
        children: [
          Transform.translate(offset: Offset(_dx * 0.35, 0), child: widget.child),
          if (progress > 0.05)
            Positioned(
              top: 0,
              bottom: 0,
              left: next ? null : 12 + 18 * progress,
              right: next ? 12 + 18 * progress : null,
              child: Center(
                child: Opacity(
                  opacity: math.min(1, progress * 1.6),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: DesignTokens.getCardBackground(brightness),
                      shape: BoxShape.circle,
                      boxShadow: [DesignTokens.shadowSubtle],
                    ),
                    child: CustomPaint(
                      painter: _RingPainter(progress, color),
                      child: Icon(
                        next ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                        color: progress >= 1 ? color : DesignTokens.getTextSecondary(brightness),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawArc(rect.deflate(3), -math.pi / 2, 2 * math.pi * progress, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

/// Opens [page] instead of the current screen, sliding in from the side.
void replaceWithSlide(BuildContext context, Widget page, {required bool fromRight}) {
  Navigator.of(context).pushReplacement(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween(begin: Offset(fromRight ? 1 : -1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ));
}
