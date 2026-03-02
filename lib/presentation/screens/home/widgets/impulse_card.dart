import 'package:flutter/material.dart';
import 'package:jugendkompass_app/data/models/impulse_model.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

class ImpulseCard extends StatelessWidget {
  final ImpulseModel impulse;
  final VoidCallback? onTap;

  const ImpulseCard({
    super.key,
    required this.impulse,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        height: 320,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
          boxShadow: [DesignTokens.shadowLargeCard],
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
                    color: DesignTokens.appBackground,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.primaryRed,
                      ),
                    ),
                  ),
                  errorWidget: Container(
                    color: DesignTokens.appBackground,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                )
              else
                Container(
                  color: DesignTokens.appBackground,
                  child: const Icon(
                    Icons.lightbulb_outline,
                    size: 48,
                    color: DesignTokens.textSecondary,
                  ),
                ),

              // Gradient overlay (transparent to dark)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),

              // Content overlay
              Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Duration badge (top left)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        impulse.durationLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Title (bottom)
                    Text(
                      impulse.displayTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
