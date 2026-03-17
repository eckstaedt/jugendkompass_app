import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/full_player_screen.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

class MiniPlayerBar extends ConsumerWidget {
  final AudioModel audio;

  const MiniPlayerBar({super.key, required this.audio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioServiceProvider);
    final positionAsync = ref.watch(audioPositionProvider);
    final durationAsync = ref.watch(audioDurationProvider);
    final playerStateAsync = ref.watch(audioPlayerStateProvider);
    final theme = Theme.of(context);

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FullPlayerScreen(),
                ),
              );
            },
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                boxShadow: [DesignTokens.shadowSubtle],
              ),
              child: Column(
                children: [
                  // Progress indicator (thin line at top with rounded corners)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: SizedBox(
                      height: 3,
                      child: positionAsync.when(
                        data: (position) {
                          final duration = durationAsync.value ?? Duration.zero;
                          final progress = duration.inSeconds > 0
                              ? position.inSeconds / duration.inSeconds
                              : 0.0;
                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DesignTokens.primaryRed,
                            ),
                          );
                        },
                        loading: () => LinearProgressIndicator(
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            DesignTokens.primaryRed,
                          ),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers / 3),
                            child: audio.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: audio.imageUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 48,
                                      height: 48,
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: Icon(
                                        Icons.podcasts,
                                        size: 24,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          width: 48,
                                          height: 48,
                                          color: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          child: Icon(
                                            Icons.podcasts,
                                            size: 24,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.podcasts,
                                      size: 24,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),

                          // Title and Artist
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  audio.title ?? audio.post?.title ?? 'Unbekannter Titel',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (audio.artist != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    audio.artist!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Play/Pause Button
                          playerStateAsync.when(
                            data: (state) {
                              final isPlaying = state.playing;
                              return IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 32,
                                ),
                                onPressed: () {
                                  if (isPlaying) {
                                    audioService.pause();
                                  } else {
                                    audioService.resume();
                                  }
                                },
                              );
                            },
                            loading: () => const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: (_, _) => IconButton(
                              icon: const Icon(Icons.play_arrow, size: 32),
                              onPressed: () {
                                audioService.playAudio(audio.audioUrl);
                              },
                            ),
                          ),

                          // Close Button
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              audioService.stop();
                              ref.read(currentAudioProvider.notifier).state =
                                  null;
                            },
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
