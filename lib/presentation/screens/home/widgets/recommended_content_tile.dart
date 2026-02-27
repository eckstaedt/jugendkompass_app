import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/recommendation_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/core/config/app_theme.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';

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
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image/Icon container (left)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? CorsNetworkImage(
                          imageUrl: item.imageUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          item.isVideo ? Icons.play_circle_outline : Icons.article_outlined,
                          size: 32,
                          color: AppTheme.primaryColor,
                        ),
                ),
              ),

              const SizedBox(width: 16),

              // Title and badges (center)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Badges row
                    Row(
                      children: [
                        // Content type badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.isVideo ? 'VIDEO' : 'ARTIKEL',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Audio badge if available
                        if (item.hasAudio) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.headphones,
                                  size: 12,
                                  color: AppTheme.successGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AUDIO',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppTheme.successGreen,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Play button (if audio available) or chevron
              if (item.hasAudio)
                IconButton(
                  onPressed: () => _playAudio(context, ref),
                  icon: const Icon(Icons.play_circle_filled),
                  color: AppTheme.primaryColor,
                  iconSize: 32,
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
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

