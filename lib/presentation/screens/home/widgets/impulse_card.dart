import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/impulse_model.dart';
import 'package:jugendkompass_app/domain/providers/translation_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

class ImpulseCard extends ConsumerStatefulWidget {
  final ImpulseModel impulse;
  final VoidCallback? onTap;

  const ImpulseCard({
    super.key,
    required this.impulse,
    this.onTap,
  });

  @override
  ConsumerState<ImpulseCard> createState() => _ImpulseCardState();
}

class _ImpulseCardState extends ConsumerState<ImpulseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final impulse = widget.impulse;

    // Translate title to the selected app language
    final titleAsync = ref.watch(translateTextProvider(impulse.displayTitle));
    final displayTitle =
        titleAsync.whenOrNull(data: (t) => t) ?? impulse.displayTitle;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Container(
            width: 240,
            height: 320,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
              boxShadow: [DesignTokens.shadowGlass],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  if (impulse.imageUrl != null)
                    CorsNetworkImage(
                      imageUrl: impulse.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: DesignTokens.getAppBackground(Theme.of(context).brightness),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: DesignTokens.primaryRed,
                          ),
                        ),
                      ),
                      errorWidget: Container(
                        color: DesignTokens.getAppBackground(Theme.of(context).brightness),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: DesignTokens.primaryRed,
                          size: 48,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: DesignTokens.getAppBackground(Theme.of(context).brightness),
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: DesignTokens.primaryRed,
                          size: 48,
                        ),
                      ),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  // Text content (bottom)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
