import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  double _currentSpeed = 1.0;

  void _showSpeedPicker(BuildContext context) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final audioService = ref.read(audioServiceProvider);
    final brightness = Theme.of(context).brightness;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusMiddleContainers)),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: DesignTokens.glassBlurSigma,
                  sigmaY: DesignTokens.glassBlurSigma),
              child: Container(
                decoration: BoxDecoration(
                  color: DesignTokens.getGlassBackground(brightness, 0.88),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(
                          DesignTokens.radiusMiddleContainers)),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DesignTokens.textSecondary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Wiedergabegeschwindigkeit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.getTextPrimary(brightness),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...speeds.map((speed) {
                      final isSelected = speed == _currentSpeed;
                      return ListTile(
                        title: Text(
                          speed == 1.0 ? '1× Normal' : '${speed}×',
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? DesignTokens.primaryRed
                                : DesignTokens.getTextPrimary(brightness),
                            fontSize: 16,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_rounded,
                                color: DesignTokens.primaryRed)
                            : null,
                        onTap: () {
                          audioService.setSpeed(speed);
                          setState(() => _currentSpeed = speed);
                          Navigator.pop(context);
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
    final brightness = theme.brightness;
    final screenWidth = MediaQuery.of(context).size.width;

    if (currentAudio == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: Text('Kein Audio ausgewählt')),
      );
    }

    return Scaffold(
      backgroundColor: brightness == Brightness.dark
          ? DesignTokens.darkAppBackground
          : const Color(0xFFF0EEF5),
      body: Stack(
        children: [
          // Blurred background image
          if (currentAudio.imageUrl != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                child: CachedNetworkImage(
                  imageUrl: currentAudio.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          // Scrim overlay
          Positioned.fill(
            child: Container(
              color: (brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white)
                  .withOpacity(0.52),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GlassCircleButton(
                        icon: Icons.keyboard_arrow_down_rounded,
                        onTap: () => Navigator.pop(context),
                        brightness: brightness,
                      ),
                      Text(
                        'Jetzt läuft',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.getTextPrimary(brightness),
                        ),
                      ),
                      // Speed pill button
                      GestureDetector(
                        onTap: () => _showSpeedPicker(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: DesignTokens.getGlassBackground(
                                    brightness, 0.5),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1),
                              ),
                              child: Text(
                                _currentSpeed == 1.0
                                    ? '1×'
                                    : '${_currentSpeed}×',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: DesignTokens.getTextPrimary(brightness),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Album Art
                        Center(
                          child: Container(
                            width: screenWidth * 0.72,
                            height: screenWidth * 0.72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusLargeCards),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.28),
                                  blurRadius: 48,
                                  offset: const Offset(0, 22),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusLargeCards),
                              child: currentAudio.imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: currentAudio.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: theme.colorScheme
                                            .surfaceContainerHighest,
                                        child: const Center(
                                            child: CircularProgressIndicator()),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: theme.colorScheme
                                            .surfaceContainerHighest,
                                        child: Icon(Icons.podcasts,
                                            size: 80,
                                            color: theme.colorScheme
                                                .onSurfaceVariant),
                                      ),
                                    )
                                  : Container(
                                      color: theme
                                          .colorScheme.surfaceContainerHighest,
                                      child: Icon(Icons.podcasts,
                                          size: 80,
                                          color: theme
                                              .colorScheme.onSurfaceVariant),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Title
                        Text(
                          currentAudio.title ??
                              currentAudio.post?.title ??
                              'Unbekannter Titel',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: DesignTokens.getTextPrimary(brightness),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (currentAudio.artist != null ||
                            currentAudio.post?.categoryName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            currentAudio.artist ??
                                currentAudio.post?.categoryName ??
                                '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: DesignTokens.getTextSecondary(brightness),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Progress bar
                        _GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                            child: positionAsync.when(
                              data: (position) {
                                final duration =
                                    durationAsync.value ?? Duration.zero;
                                return ProgressBar(
                                  progress: position,
                                  total: duration,
                                  onSeek: audioService.seek,
                                  barHeight: 5,
                                  thumbRadius: 9,
                                  progressBarColor: DesignTokens.primaryRed,
                                  thumbColor: DesignTokens.primaryRed,
                                  baseBarColor:
                                      DesignTokens.primaryRed.withOpacity(0.15),
                                  timeLabelTextStyle:
                                      theme.textTheme.bodySmall?.copyWith(
                                    color: DesignTokens.getTextSecondary(
                                        brightness),
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                              loading: () => LinearProgressIndicator(
                                color: DesignTokens.primaryRed,
                                backgroundColor:
                                    DesignTokens.primaryRed.withOpacity(0.15),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Playback controls
                        _GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Previous
                                IconButton(
                                  iconSize: 30,
                                  icon: Icon(
                                    Icons.skip_previous_rounded,
                                    color: hasPrevious
                                        ? DesignTokens.getTextPrimary(brightness)
                                        : DesignTokens
                                            .getTextSecondary(brightness)
                                            .withOpacity(0.35),
                                  ),
                                  onPressed: hasPrevious
                                      ? () async {
                                          await audioService.playPrevious();
                                          final idx =
                                              audioService.currentQueueIndex;
                                          ref
                                              .read(currentQueueIndexProvider
                                                  .notifier)
                                              .state = idx;
                                          ref
                                              .read(
                                                  currentAudioProvider.notifier)
                                              .state = audioService.currentAudio;
                                        }
                                      : null,
                                ),
                                // Rewind 10s
                                IconButton(
                                  iconSize: 30,
                                  icon: Icon(Icons.replay_10_rounded,
                                      color:
                                          DesignTokens.getTextPrimary(brightness)),
                                  onPressed: () => audioService.seek(
                                      audioService.position -
                                          const Duration(seconds: 10)),
                                ),
                                // Play / Pause
                                playerStateAsync.when(
                                  data: (state) {
                                    final isPlaying = state.playing;
                                    final isBuffering = state.processingState ==
                                            just_audio.ProcessingState.loading ||
                                        state.processingState ==
                                            just_audio.ProcessingState.buffering;
                                    if (isBuffering) {
                                      return const _PlayPauseShell(
                                        child: SizedBox(
                                          width: 34,
                                          height: 34,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: Colors.white),
                                        ),
                                      );
                                    }
                                    return GestureDetector(
                                      onTap: () => isPlaying
                                          ? audioService.pause()
                                          : audioService.resume(),
                                      child: _PlayPauseShell(
                                        child: Icon(
                                          isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          size: 44,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                  loading: () => const _PlayPauseShell(
                                    child: SizedBox(
                                      width: 34,
                                      height: 34,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 3, color: Colors.white),
                                    ),
                                  ),
                                  error: (_, __) => GestureDetector(
                                    onTap: () =>
                                        audioService.playAudio(currentAudio.audioUrl),
                                    child: const _PlayPauseShell(
                                      child: Icon(Icons.play_arrow_rounded,
                                          size: 44, color: Colors.white),
                                    ),
                                  ),
                                ),
                                // Forward 10s
                                IconButton(
                                  iconSize: 30,
                                  icon: Icon(Icons.forward_10_rounded,
                                      color:
                                          DesignTokens.getTextPrimary(brightness)),
                                  onPressed: () => audioService.seek(
                                      audioService.position +
                                          const Duration(seconds: 10)),
                                ),
                                // Next
                                IconButton(
                                  iconSize: 30,
                                  icon: Icon(
                                    Icons.skip_next_rounded,
                                    color: hasNext
                                        ? DesignTokens.getTextPrimary(brightness)
                                        : DesignTokens
                                            .getTextSecondary(brightness)
                                            .withOpacity(0.35),
                                  ),
                                  onPressed: hasNext
                                      ? () async {
                                          await audioService.playNext();
                                          final idx =
                                              audioService.currentQueueIndex;
                                          ref
                                              .read(currentQueueIndexProvider
                                                  .notifier)
                                              .state = idx;
                                          ref
                                              .read(
                                                  currentAudioProvider.notifier)
                                              .state = audioService.currentAudio;
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Queue section
                        if (queue.length > 1) ...[
                          const SizedBox(height: 24),
                          _GlassCard(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Warteschlange (${queue.length})',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: DesignTokens.getTextPrimary(
                                              brightness),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          audioService.clearQueue();
                                          ref
                                              .read(
                                                  audioQueueProvider.notifier)
                                              .state = [];
                                          ref
                                              .read(currentQueueIndexProvider
                                                  .notifier)
                                              .state = 0;
                                        },
                                        child: Text('Leeren',
                                            style: TextStyle(
                                                color:
                                                    DesignTokens.primaryRed)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ...queue.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final audio = entry.value;
                                    final isCurrent = idx == currentIndex;
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: audio.imageUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl: audio.imageUrl!,
                                                width: 44,
                                                height: 44,
                                                fit: BoxFit.cover,
                                                errorWidget: (_, __, ___) =>
                                                    const SizedBox(
                                                        width: 44,
                                                        height: 44,
                                                        child: Icon(
                                                            Icons.podcasts)),
                                              )
                                            : const SizedBox(
                                                width: 44,
                                                height: 44,
                                                child: Icon(Icons.podcasts)),
                                      ),
                                      title: Text(
                                        audio.title ?? 'Unbekannter Titel',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: isCurrent
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isCurrent
                                              ? DesignTokens.primaryRed
                                              : DesignTokens.getTextPrimary(
                                                  brightness),
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: isCurrent
                                          ? Icon(Icons.graphic_eq_rounded,
                                              color: DesignTokens.primaryRed)
                                          : IconButton(
                                              icon: const Icon(Icons.close,
                                                  size: 18),
                                              onPressed: () {
                                                audioService
                                                    .removeFromQueue(idx);
                                                ref
                                                    .read(audioQueueProvider
                                                        .notifier)
                                                    .state = List.from(
                                                        audioService.queue);
                                              },
                                            ),
                                      onTap: !isCurrent
                                          ? () async {
                                              await audioService
                                                  .skipToQueueIndex(idx);
                                              ref
                                                  .read(
                                                      currentQueueIndexProvider
                                                          .notifier)
                                                  .state = idx;
                                              ref
                                                  .read(currentAudioProvider
                                                      .notifier)
                                                  .state = audio;
                                            }
                                          : null,
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Recommended
                        recommendedAsync.when(
                          data: (recommended) {
                            if (recommended.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 28),
                                Text(
                                  'Das könnte dir auch gefallen',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color:
                                        DesignTokens.getTextPrimary(brightness),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 130,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: recommended.length,
                                    itemBuilder: (_, i) {
                                      final audio = recommended[i];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 12),
                                        child: GestureDetector(
                                          onTap: () {
                                            audioService.addToQueue(audio);
                                            ref
                                                .read(
                                                    audioQueueProvider.notifier)
                                                .state =
                                                List<AudioModel>.from(
                                                    audioService.queue);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  '${audio.title ?? "Audio"} zur Warteschlange hinzugefügt'),
                                              duration:
                                                  const Duration(seconds: 2),
                                            ));
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                DesignTokens.radiusButtons),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                  sigmaX: DesignTokens
                                                      .glassBlurSigma,
                                                  sigmaY: DesignTokens
                                                      .glassBlurSigma),
                                              child: Container(
                                                width: 130,
                                                decoration: BoxDecoration(
                                                  color: DesignTokens
                                                      .getGlassBackground(
                                                          brightness, 0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          DesignTokens
                                                              .radiusButtons),
                                                  border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.2),
                                                      width: 1),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          const BorderRadius.only(
                                                        topLeft: Radius.circular(
                                                            DesignTokens
                                                                .radiusButtons),
                                                        topRight: Radius.circular(
                                                            DesignTokens
                                                                .radiusButtons),
                                                      ),
                                                      child: audio.imageUrl != null
                                                          ? CachedNetworkImage(
                                                              imageUrl:
                                                                  audio.imageUrl!,
                                                              width: 130,
                                                              height: 72,
                                                              fit: BoxFit.cover,
                                                              errorWidget: (_,
                                                                      __,
                                                                      ___) =>
                                                                  Container(
                                                                      width: 130,
                                                                      height: 72,
                                                                      color: theme.colorScheme.surfaceContainerHighest,
                                                                      child: const Icon(Icons.podcasts, size: 28)),
                                                            )
                                                          : Container(
                                                              width: 130,
                                                              height: 72,
                                                              color: theme.colorScheme.surfaceContainerHighest,
                                                              child: const Icon(Icons.podcasts, size: 28)),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(8),
                                                      child: Text(
                                                        audio.title ??
                                                            audio.post?.title ??
                                                            'Unbekannter Titel',
                                                        style: theme
                                                            .textTheme.bodySmall
                                                            ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: DesignTokens
                                                              .getTextPrimary(
                                                                  brightness),
                                                        ),
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DesignTokens.glassBlurSigma,
          sigmaY: DesignTokens.glassBlurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: DesignTokens.getGlassBackground(brightness, 0.55),
            borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
            boxShadow: [DesignTokens.shadowGlass],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Brightness brightness;

  const _GlassCircleButton({
    required this.icon,
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DesignTokens.getGlassBackground(brightness, 0.5),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.22), width: 1),
            ),
            child: Icon(icon,
                size: 22, color: DesignTokens.getTextPrimary(brightness)),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseShell extends StatelessWidget {
  final Widget child;
  const _PlayPauseShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: DesignTokens.primaryRed,
        shape: BoxShape.circle,
        boxShadow: [DesignTokens.shadowButton],
      ),
      child: Center(child: child),
    );
  }
}
