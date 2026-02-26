import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAudio = ref.watch(currentAudioProvider);
    final audioService = ref.watch(audioServiceProvider);
    final positionAsync = ref.watch(audioPositionProvider);
    final durationAsync = ref.watch(audioDurationProvider);
    final playerStateAsync = ref.watch(audioPlayerStateProvider);
    final theme = Theme.of(context);

    if (currentAudio == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Player'),
        ),
        body: const Center(
          child: Text('Kein Audio ausgewählt'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jetzt läuft'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Album Art
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: currentAudio.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: currentAudio.imageUrl!,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 300,
                          height: 300,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 300,
                          height: 300,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.podcasts,
                            size: 100,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.podcasts,
                          size: 100,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Title and Artist
              Text(
                currentAudio.title ?? 'Unbekannter Titel',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (currentAudio.artist != null) ...[
                const SizedBox(height: 8),
                Text(
                  currentAudio.artist!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),

              // Progress Bar
              positionAsync.when(
                data: (position) {
                  final duration = durationAsync.value ?? Duration.zero;
                  return ProgressBar(
                    progress: position,
                    total: duration,
                    onSeek: (duration) {
                      audioService.seek(duration);
                    },
                    barHeight: 4,
                    thumbRadius: 8,
                    timeLabelTextStyle: theme.textTheme.bodyMedium,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),

              // Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rewind 10 seconds
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.replay_10),
                    onPressed: () {
                      final currentPos = audioService.position;
                      audioService.seek(currentPos - const Duration(seconds: 10));
                    },
                  ),
                  const SizedBox(width: 24),

                  // Play/Pause Button
                  playerStateAsync.when(
                    data: (state) {
                      final isPlaying = state.playing;
                      final isBuffering = state.processingState ==
                              just_audio.ProcessingState.loading ||
                          state.processingState ==
                              just_audio.ProcessingState.buffering;

                      if (isBuffering) {
                        return SizedBox(
                          width: 72,
                          height: 72,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      }

                      return FilledButton(
                        onPressed: () {
                          if (isPlaying) {
                            audioService.pause();
                          } else {
                            audioService.resume();
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(24),
                          shape: const CircleBorder(),
                          minimumSize: const Size(72, 72),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 40,
                        ),
                      );
                    },
                    loading: () => SizedBox(
                      width: 72,
                      height: 72,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    error: (_, _) => FilledButton(
                      onPressed: () {
                        audioService.playAudio(currentAudio.audioUrl);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(24),
                        shape: const CircleBorder(),
                        minimumSize: const Size(72, 72),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Forward 10 seconds
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.forward_10),
                    onPressed: () {
                      final currentPos = audioService.position;
                      audioService.seek(currentPos + const Duration(seconds: 10));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Speed Control
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    'Geschwindigkeit:',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 0.75, label: Text('0.75x')),
                      ButtonSegment(value: 1.0, label: Text('1x')),
                      ButtonSegment(value: 1.25, label: Text('1.25x')),
                      ButtonSegment(value: 1.5, label: Text('1.5x')),
                    ],
                    selected: {1.0},
                    onSelectionChanged: (Set<double> selected) {
                      audioService.setSpeed(selected.first);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
