import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/recommendation_provider.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

class RecommendedContentTile extends ConsumerStatefulWidget {
  final RecommendedItem item;
  final VoidCallback? onTap;

  const RecommendedContentTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  ConsumerState<RecommendedContentTile> createState() => _RecommendedContentTileState();
}

class _RecommendedContentTileState extends ConsumerState<RecommendedContentTile>
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
    final item = widget.item;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: DesignTokens.glassBlurSigma,
                  sigmaY: DesignTokens.glassBlurSigma),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: DesignTokens.glassBackground(0.20),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [DesignTokens.shadowGlass],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingSmall),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: DesignTokens.appBackground,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                          boxShadow: [DesignTokens.shadowSubtle],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                              ? CorsNetworkImage(imageUrl: item.imageUrl!, width: 80, height: 80, fit: BoxFit.cover)
                              : Icon(item.isVideo ? Icons.play_circle_outline : Icons.article_outlined, size: 32, color: DesignTokens.primaryRed),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                BadgeWidget(label: item.isVideo ? 'VIDEO' : 'ARTIKEL', backgroundColor: DesignTokens.redBackground, textColor: DesignTokens.primaryRed),
                                if (item.hasAudio)
                                  BadgeWidget(label: 'AUDIO', backgroundColor: DesignTokens.successGreen.withOpacity(0.12), textColor: DesignTokens.successGreen, icon: Icons.headphones),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
