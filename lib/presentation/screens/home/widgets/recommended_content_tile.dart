import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/recommendation_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
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

              // Play button (if audio available) or chevron
              if (item.hasAudio)
                GestureDetector(onTap: () => _playAudio(context, ref), child: Icon(Icons.play_circle_filled, color: DesignTokens.primaryRed, size: 40))
              else
                Icon(Icons.chevron_right, color: DesignTokens.textSecondary, size: 28),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playAudio(BuildContext context, WidgetRef ref) async {
    if (!item.hasAudio) return;

    try {
      // Fetch the audio
      final audioRepository = ref.read(audioRepositoryProvider);
      final audio = await audioRepository.getAudioById(item.audioId!);

      if (audio == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio nicht gefunden'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Set as queue with single audio
      final audioService = ref.read(audioServiceProvider);
      await audioService.setQueue([audio], startIndex: 0);

      // Update providers
      ref.read(audioQueueProvider.notifier).state = [audio];
      ref.read(currentQueueIndexProvider.notifier).state = 0;
      ref.read(currentAudioProvider.notifier).state = audio;

      // Don't navigate to full player - let the mini player bar handle it
      // The mini player bar will be shown automatically in the bottom nav
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Abspielen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

