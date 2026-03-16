import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/recommendation_provider.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

class RecommendedContentTile extends ConsumerWidget {
  final RecommendedItem item;
  final VoidCallback? onTap;

  const RecommendedContentTile({
    super.key,
    required this.item,
    this.onTap,
  });

  String _getMonthName(int month) {
    const months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: DesignTokens.glassBlurSigma,
              sigmaY: DesignTokens.glassBlurSigma),
          child: Container(
            // force the tile to expand to whatever horizontal space it can take
            // The outer HomeScreen already provides symmetric horizontal padding,
            // so we avoid additional horizontal margins here to match the verse card
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              // slightly deeper opacity so tile stands out more from app background
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
              // Image/Icon container (left)
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

              // Title and badges (center)
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

              // Date badge
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Builder(
                  builder: (context) {
                    final date = item.contentType == 'video'
                        ? (item.data as dynamic).createdAt as DateTime
                        : (item.data as dynamic).createdAt as DateTime;
                    
                    // Format: "16. März 2026"
                    final dateLabel = '${date.day}. ${_getMonthName(date.month)} ${date.year}';
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DesignTokens.glassBackground(0.3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: DesignTokens.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }
}
