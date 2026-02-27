import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAudio = ref.watch(currentAudioProvider);
    final audioService = ref.watch(audioServiceProvider);
    final positionAsync = ref.watch(audioPositionProvider);
    final durationAsync = ref.watch(audioDurationProvider);
    final playerStateAsync = ref.watch(audioPlayerStateProvider);
    final hasNext = ref.watch(hasNextAudioProvider);
    final hasPrevious = ref.watch(hasPreviousAudioProvider);
    final queue = ref.watch(audioQueueProvider);
    final currentIndex = ref.watch(currentQueueIndexProvider);
    final recommendedAsync = ref.watch(recommendedAudiosProvider);
    final theme = Theme.of(context);

    if (currentAudio == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: Text('Kein Audio ausgewählt')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jetzt läuft'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
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
                    // Previous Button
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_previous),
                      onPressed: hasPrevious
                          ? () async {
                              await audioService.playPrevious();
                              // Update providers
                              final newIndex = audioService.currentQueueIndex;
                              ref
                                      .read(currentQueueIndexProvider.notifier)
                                      .state =
                                  newIndex;
                              ref.read(currentAudioProvider.notifier).state =
                                  audioService.currentAudio;
                            }
                          : null,
                    ),
                    const SizedBox(width: 8),

                    // Rewind 10 seconds
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.replay_10),
                      onPressed: () {
                        final currentPos = audioService.position;
                        audioService.seek(
                          currentPos - const Duration(seconds: 10),
                        );
                      },
                    ),
                    const SizedBox(width: 16),

                    // Play/Pause Button
                    playerStateAsync.when(
                      data: (state) {
                        final isPlaying = state.playing;
                        final isBuffering =
                            state.processingState ==
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
                        child: const Icon(Icons.play_arrow, size: 40),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Forward 10 seconds
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.forward_10),
                      onPressed: () {
                        final currentPos = audioService.position;
                        audioService.seek(
                          currentPos + const Duration(seconds: 10),
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    // Next Button
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_next),
                      onPressed: hasNext
                          ? () async {
                              await audioService.playNext();
                              // Update providers
                              final newIndex = audioService.currentQueueIndex;
                              ref
                                      .read(currentQueueIndexProvider.notifier)
                                      .state =
                                  newIndex;
                              ref.read(currentAudioProvider.notifier).state =
                                  audioService.currentAudio;
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Speed Control
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    Text('Geschwindigkeit:', style: theme.textTheme.labelLarge),
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

                // Queue Section
                if (queue.length > 1) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Warteschlange (${queue.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          audioService.clearQueue();
                          ref.read(audioQueueProvider.notifier).state = [];
                          ref.read(currentQueueIndexProvider.notifier).state =
                              0;
                        },
                        child: const Text('Leeren'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...queue.asMap().entries.map((entry) {
                    final index = entry.key;
                    final audio = entry.value;
                    final isCurrentlyPlaying = index == currentIndex;

                    return Card(
                      color: isCurrentlyPlaying
                          ? theme.colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: audio.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: audio.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 50,
                                    height: 50,
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        width: 50,
                                        height: 50,
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: const Icon(
                                          Icons.podcasts,
                                          size: 24,
                                        ),
                                      ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.podcasts, size: 24),
                                ),
                        ),
                        title: Text(
                          audio.title ?? 'Unbekannter Titel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: isCurrentlyPlaying
                              ? TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                )
                              : null,
                        ),
                        subtitle: audio.durationSeconds != null
                            ? Text(_formatDuration(audio.durationSeconds!))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCurrentlyPlaying)
                              Icon(
                                Icons.graphic_eq,
                                color: theme.colorScheme.primary,
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: () async {
                                  await audioService.skipToQueueIndex(index);
                                  ref
                                          .read(
                                            currentQueueIndexProvider.notifier,
                                          )
                                          .state =
                                      index;
                                  ref
                                          .read(currentAudioProvider.notifier)
                                          .state =
                                      audio;
                                },
                              ),
                            if (!isCurrentlyPlaying)
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  audioService.removeFromQueue(index);
                                  ref.read(audioQueueProvider.notifier).state =
                                      List.from(audioService.queue);
                                },
                              ),
                          ],
                        ),
                        onTap: !isCurrentlyPlaying
                            ? () async {
                                await audioService.skipToQueueIndex(index);
                                ref
                                        .read(
                                          currentQueueIndexProvider.notifier,
                                        )
                                        .state =
                                    index;
                                ref.read(currentAudioProvider.notifier).state =
                                    audio;
                              }
                            : null,
                      ),
                    );
                  }),
                ],

                // Recommended Audios Section
                recommendedAsync.when(
                  data: (recommendedAudios) {
                    if (recommendedAudios.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Das könnte dir auch gefallen',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: recommendedAudios.length,
                            itemBuilder: (context, index) {
                              final audio = recommendedAudios[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () {
                                    // Add to queue
                                    audioService.addToQueue(audio);
                                    final updatedQueue = List<AudioModel>.from(
                                      audioService.queue,
                                    );
                                    ref
                                            .read(audioQueueProvider.notifier)
                                            .state =
                                        updatedQueue;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${audio.title ?? "Audio"} zur Warteschlange hinzugefügt',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 140,
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Thumbnail
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          child: audio.imageUrl != null
                                              ? CachedNetworkImage(
                                                  imageUrl: audio.imageUrl!,
                                                  width: 140,
                                                  height: 70,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                        width: 140,
                                                        height: 70,
                                                        color: theme
                                                            .colorScheme
                                                            .surfaceContainerHighest,
                                                      ),
                                                  errorWidget:
                                                      (
                                                        context,
                                                        url,
                                                        error,
                                                      ) => Container(
                                                        width: 140,
                                                        height: 70,
                                                        color: theme
                                                            .colorScheme
                                                            .surfaceContainerHighest,
                                                        child: const Icon(
                                                          Icons.podcasts,
                                                          size: 32,
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  width: 140,
                                                  height: 70,
                                                  color: theme
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                                  child: const Icon(
                                                    Icons.podcasts,
                                                    size: 32,
                                                  ),
                                                ),
                                        ),
                                        // Title
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(
                                            audio.title ?? 'Unbekannter Titel',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ], // Schließt children: [
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m ${secs}s';
    }
  }
}
