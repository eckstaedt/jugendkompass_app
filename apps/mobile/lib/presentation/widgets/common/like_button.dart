import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/domain/providers/like_provider.dart';

/// A compact heart button that shows the total like count.
/// Drop it anywhere – it is fully self-contained.
///
/// [contentId]   – unique ID of the content (post id, audio id, etc.)
/// [contentType] – one of: 'post', 'audio', 'edition', 'video', 'impulse', 'message'
class LikeButton extends ConsumerWidget {
  final String contentId;
  final String contentType;

  const LikeButton({
    super.key,
    required this.contentId,
    required this.contentType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (id: contentId, type: contentType);
    final likeAsync = ref.watch(likeProvider(key));

    return likeAsync.when(
      loading: () => const _LikeButtonShell(liked: false, count: 0, loading: true),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) => _LikeButtonShell(
        liked: state.liked,
        count: state.likeCount,
        loading: false,
        onTap: () => ref.read(likeProvider(key).notifier).toggle(),
      ),
    );
  }
}

class _LikeButtonShell extends StatefulWidget {
  final bool liked;
  final int count;
  final bool loading;
  final VoidCallback? onTap;

  const _LikeButtonShell({
    required this.liked,
    required this.count,
    required this.loading,
    this.onTap,
  });

  @override
  State<_LikeButtonShell> createState() => _LikeButtonShellState();
}

class _LikeButtonShellState extends State<_LikeButtonShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_LikeButtonShell old) {
    super.didUpdateWidget(old);
    if (widget.liked != old.liked && widget.liked) {
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.liked
        ? DesignTokens.primaryRed
        : DesignTokens.getTextSecondary(Theme.of(context).brightness);

    return GestureDetector(
      onTap: widget.loading ? null : widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Icon(
                widget.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 16,
                color: color,
              ),
            ),
            if (widget.count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '${widget.count}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
