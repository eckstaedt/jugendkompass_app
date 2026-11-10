import 'package:flutter/material.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

/// Thin reading-progress bar for detail screens (use as `AppBar.bottom`).
///
/// Stays invisible until the reader has scrolled past [revealAfter] pixels
/// (e.g. the height of the cover image) and then fills up with the scroll
/// position of [controller].
class ReadingProgressBar extends StatefulWidget implements PreferredSizeWidget {
  const ReadingProgressBar({
    super.key,
    required this.controller,
    this.revealAfter = 0,
    this.height = 3,
  });

  final ScrollController controller;
  final double revealAfter;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  State<ReadingProgressBar> createState() => _ReadingProgressBarState();
}

class _ReadingProgressBarState extends State<ReadingProgressBar> {
  double _progress = 0;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant ReadingProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_update);
      widget.controller.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (!widget.controller.hasClients) return;
    final position = widget.controller.position;
    final max = position.maxScrollExtent;
    final offset = position.pixels.clamp(0.0, max > 0 ? max : 0.0);
    final progress = max > 0 ? offset / max : 0.0;
    final visible = position.pixels > widget.revealAfter;
    if ((progress - _progress).abs() > 0.002 || visible != _visible) {
      setState(() {
        _progress = progress;
        _visible = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        height: widget.height,
        child: LinearProgressIndicator(
          value: _progress,
          minHeight: widget.height,
          backgroundColor: Colors.transparent,
          color: dark ? DesignTokens.primaryRedOnDark : DesignTokens.primaryRed,
        ),
      ),
    );
  }
}
