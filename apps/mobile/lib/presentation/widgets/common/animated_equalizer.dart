import 'package:flutter/material.dart';

/// Animated equalizer bars that show audio is currently playing.
/// Used in the featured episode card and podcast list thumbnails.
class AnimatedEqualizer extends StatefulWidget {
  final Color color;
  final double size;
  final int barCount;

  const AnimatedEqualizer({
    super.key,
    this.color = Colors.white,
    this.size = 20,
    this.barCount = 3,
  });

  @override
  State<AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<AnimatedEqualizer>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  // Different durations & delays per bar for organic feel
  static const _durations = [450, 550, 400, 500, 380];
  static const _delays = [0, 120, 60, 180, 90];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.barCount, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _durations[i % _durations.length]),
      );
    });

    _animations = List.generate(widget.barCount, (i) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      );
    });

    // Start each bar with a staggered delay
    for (var i = 0; i < widget.barCount; i++) {
      Future.delayed(Duration(milliseconds: _delays[i % _delays.length]), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = widget.size / (widget.barCount * 2);
    final gap = barWidth * 0.6;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, _) {
              return Container(
                width: barWidth,
                height: widget.size * _animations[i].value,
                margin: EdgeInsets.only(right: i < widget.barCount - 1 ? gap : 0),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(barWidth / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
