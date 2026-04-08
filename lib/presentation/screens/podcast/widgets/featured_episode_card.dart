import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/widgets/common/animated_equalizer.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';

class FeaturedEpisodeCard extends StatelessWidget {
  final AudioModel audio;
  final VoidCallback onPlay;
  final bool isPlaying;

  const FeaturedEpisodeCard({
    super.key,
    required this.audio,
    required this.onPlay,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // make sure the card takes full width of its parent container
      width: double.infinity,
      height: 220,
      margin: const EdgeInsets.all(DesignTokens.spacingMedium),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
        boxShadow: [DesignTokens.shadowGlass],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background Image
            if (audio.imageUrl != null)
              Positioned.fill(
                child: CorsNetworkImage(
                  imageUrl: audio.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.podcasts, size: 64),
                  ),
                ),
              ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                          color: DesignTokens.primaryRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                          child: Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      audio.title ?? audio.post?.title ?? 'Unbekannter Titel',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              offset: Offset.zero,
                              blurRadius: 12,
                              color: Colors.black.withOpacity(0.9),
                            ),
                            Shadow(
                              offset: Offset.zero,
                              blurRadius: 24,
                              color: Colors.black.withOpacity(0.7),
                            ),
                            Shadow(
                              offset: Offset.zero,
                              blurRadius: 48,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (audio.description != null) ...[
                      const SizedBox(height: 4),
                      Html(
                        data: audio.description!,
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            color: Colors.white.withOpacity(0.85),
                            fontSize: FontSize(theme.textTheme.bodyMedium?.fontSize ?? 14),
                            maxLines: 2,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                          "p": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            color: Colors.white.withOpacity(0.85),
                            fontSize: FontSize(theme.textTheme.bodyMedium?.fontSize ?? 14),
                            maxLines: 2,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                        },
                      ),
                    ],
                    const SizedBox(height: DesignTokens.spacingMedium),

                    // Play Button
                    ElevatedButton.icon(
                      onPressed: onPlay,
                      icon: isPlaying
                          ? const AnimatedEqualizer(
                              color: Colors.white,
                              size: 20,
                              barCount: 3,
                            )
                          : const Icon(Icons.play_arrow, size: 20),
                      label: Text(isPlaying
                          ? AppTranslations.t('now_playing')
                          : AppTranslations.t('play')),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                          ),
                        ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
