import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';

class AudioPlayerScreen extends ConsumerWidget {
  const AudioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final translate = ref.watch(stringTranslatorProvider);
    
    final audioListAsync = ref.watch(audioListProvider);
    final currentAudio = ref.watch(currentAudioProvider);
    final audioService = ref.watch(audioServiceProvider);
    final positionAsync = ref.watch(audioPositionProvider);
    final durationAsync = ref.watch(audioDurationProvider);
    final playerStateAsync = ref.watch(audioPlayerStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audios'),
        centerTitle: true,
      ),
      body: audioListAsync.when(
        data: (audioList) {
          if (audioList.isEmpty) {
            return EmptyState(
              icon: Icons.headphones_outlined,
              title: translate('no_audios_available'),
              message: translate('no_audio_content'),
            );
          }

          return Column(
            children: [
              // Currently Playing Section
              if (currentAudio != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Album Art
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: currentAudio.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: currentAudio.imageUrl!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 200,
                                height: 200,
                                color: Theme.of(context).colorScheme.surface,
                                child: Icon(
                                  Icons.headphones,
                                  size: 80,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Title and Artist
                      Text(
                        currentAudio.title ?? currentAudio.post?.title ?? translate('unknown_title'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (currentAudio.artist != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          currentAudio.artist!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Progress Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: positionAsync.when(
                          data: (position) {
                            final duration = durationAsync.value ?? Duration.zero;
                            return ProgressBar(
                              progress: position,
                              total: duration,
                              onSeek: (duration) {
                                audioService.seek(duration);
                              },
                              barHeight: 4,
                              thumbRadius: 6,
                              timeLabelTextStyle: Theme.of(context).textTheme.bodySmall,
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Playback Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 36,
                            icon: const Icon(Icons.replay_10),
                            onPressed: () {
                              final currentPos = audioService.position;
                              audioService.seek(currentPos - const Duration(seconds: 10));
                            },
                          ),
                          const SizedBox(width: 16),
                          playerStateAsync.when(
                            data: (state) {
                              final isPlaying = state.playing;
                              final isBuffering = state.processingState == just_audio.ProcessingState.loading ||
                                  state.processingState == just_audio.ProcessingState.buffering;

                              if (isBuffering) {
                                return const CircularProgressIndicator();
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
                                  padding: const EdgeInsets.all(20),
                                  shape: const CircleBorder(),
                                ),
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 36,
                                ),
                              );
                            },
                            loading: () => const CircularProgressIndicator(),
                            error: (_, _) => FilledButton(
                              onPressed: () {
                                audioService.playAudio(currentAudio.audioUrl);
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.all(20),
                                shape: const CircleBorder(),
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            iconSize: 36,
                            icon: const Icon(Icons.forward_10),
                            onPressed: () {
                              final currentPos = audioService.position;
                              audioService.seek(currentPos + const Duration(seconds: 10));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Speed Control
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Geschwindigkeit: '),
                          SegmentedButton<double>(
                            segments: const [
                              ButtonSegment(value: 0.75, label: Text('0.75x')),
                              ButtonSegment(value: 1.0, label: Text('1x')),
                              ButtonSegment(value: 1.25, label: Text('1.25x')),
                              ButtonSegment(value: 1.5, label: Text('1.5x')),
                            ],
                            selected: {audioService.player.speed},
                            onSelectionChanged: (Set<double> newSelection) {
                              audioService.setSpeed(newSelection.first);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Audio List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: audioList.length,
                  itemBuilder: (context, index) {
                    final audio = audioList[index];
                    final isCurrentlyPlaying = currentAudio?.id == audio.id;

                    return Card(
                      child: ListTile(
                        leading: audio.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: audio.imageUrl!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.headphones,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                        title: Text(
                          audio.title ?? translate('unknown_title'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: isCurrentlyPlaying
                              ? TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                )
                              : null,
                        ),
                        subtitle: audio.artist != null
                            ? Text(audio.artist!)
                            : null,
                        trailing: isCurrentlyPlaying
                            ? Icon(
                                Icons.equalizer,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () async {
                          ref.read(currentAudioProvider.notifier).state = audio;
                          await audioService.playAudio(audio.audioUrl);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => LoadingIndicator(
          message: translate('loading_audios'),
        ),
        error: (error, stack) => ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(audioListProvider);
          },
        ),
      ),
    );
  }
}
