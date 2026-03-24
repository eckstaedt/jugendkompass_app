import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/full_player_screen.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart'
    show kFullPlayerRouteName, currentAudioNotifier;

// ─── Audio Output Route ──────────────────────────────────────────────────────

enum _AudioOutput { phone, headphones, bluetooth, car }

final _audioOutputProvider = StateProvider<_AudioOutput>((_) => _AudioOutput.phone);

IconData _outputIcon(_AudioOutput output) {
  switch (output) {
    case _AudioOutput.phone:
      return Icons.phone_android;
    case _AudioOutput.headphones:
      return Icons.headphones;
    case _AudioOutput.bluetooth:
      return Icons.bluetooth_audio;
    case _AudioOutput.car:
      return Icons.directions_car;
  }
}

String _outputLabel(_AudioOutput output) {
  switch (output) {
    case _AudioOutput.phone:
      return 'Lautsprecher (Handy)';
    case _AudioOutput.headphones:
      return 'Kopfhörer';
    case _AudioOutput.bluetooth:
      return 'Bluetooth';
    case _AudioOutput.car:
      return 'Auto';
  }
}

// ─── Mini Player Bar ─────────────────────────────────────────────────────────

class MiniPlayerBar extends ConsumerWidget {
  final AudioModel audio;
  final GlobalKey<NavigatorState>? navigatorKey;

  const MiniPlayerBar({super.key, required this.audio, this.navigatorKey});

  void _showOutputPicker(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final currentOutput = ref.read(_audioOutputProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radiusMiddleContainers),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: DesignTokens.glassBlurSigma,
                sigmaY: DesignTokens.glassBlurSigma,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: DesignTokens.getGlassBackground(brightness, 0.92),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(DesignTokens.radiusMiddleContainers),
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
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
                      'Audiowiedergabe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.getTextPrimary(brightness),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._AudioOutput.values.map((output) {
                      final isSelected = output == currentOutput;
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? DesignTokens.primaryRed.withOpacity(0.12)
                                : DesignTokens.getCardBackground(brightness).withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _outputIcon(output),
                            color: isSelected
                                ? DesignTokens.primaryRed
                                : DesignTokens.getTextSecondary(brightness),
                            size: 22,
                          ),
                        ),
                        title: Text(
                          _outputLabel(output),
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? DesignTokens.primaryRed
                                : DesignTokens.getTextPrimary(brightness),
                            fontSize: 15,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_rounded,
                                color: DesignTokens.primaryRed)
                            : null,
                        onTap: () {
                          ref.read(_audioOutputProvider.notifier).state = output;
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

  void _openFullPlayer(BuildContext context) {
    final nav = navigatorKey?.currentState ??
        Navigator.of(context, rootNavigator: true);
    nav.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: kFullPlayerRouteName),
        builder: (context) => const FullPlayerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioServiceProvider);
    final positionAsync = ref.watch(audioPositionProvider);
    final durationAsync = ref.watch(audioDurationProvider);
    final playerStateAsync = ref.watch(audioPlayerStateProvider);
    final currentOutput = ref.watch(_audioOutputProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progressBgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openFullPlayer(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DesignTokens.glassBlurSigma,
              sigmaY: DesignTokens.glassBlurSigma,
            ),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? DesignTokens.darkCardBackground.withOpacity(0.96)
                    : theme.colorScheme.surface.withOpacity(0.97),
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusButtons),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Progress indicator – thin line at top
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(DesignTokens.radiusButtons),
                      topRight: Radius.circular(DesignTokens.radiusButtons),
                    ),
                    child: SizedBox(
                      height: 3,
                      child: positionAsync.when(
                        data: (position) {
                          final duration =
                              durationAsync.value ?? Duration.zero;
                          final progress = duration.inMilliseconds > 0
                              ? (position.inMilliseconds /
                                      duration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                              : 0.0;
                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor: progressBgColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DesignTokens.primaryRed,
                            ),
                          );
                        },
                        loading: () => LinearProgressIndicator(
                          backgroundColor: progressBgColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            DesignTokens.primaryRed,
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // Main content row
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: audio.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: audio.imageUrl!,
                                    width: 46,
                                    height: 46,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 46,
                                      height: 46,
                                      color: theme.colorScheme
                                          .surfaceContainerHighest,
                                      child: Icon(
                                        Icons.podcasts,
                                        size: 22,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          width: 46,
                                          height: 46,
                                          color: theme.colorScheme
                                              .surfaceContainerHighest,
                                          child: Icon(
                                            Icons.podcasts,
                                            size: 22,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                  )
                                : Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.podcasts,
                                      size: 22,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                          ),

                          const SizedBox(width: 10),

                          // Title and subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  audio.title ??
                                      audio.post?.title ??
                                      'Unbekannter Titel',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (audio.artist != null ||
                                    audio.post?.categoryName != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    audio.artist ??
                                        audio.post?.categoryName ??
                                        '',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 4),

                          // Audio output icon (speaker / headphones / car)
                          GestureDetector(
                            onTap: () => _showOutputPicker(context, ref),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                _outputIcon(currentOutput),
                                size: 22,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),

                          // Play / Pause button
                          playerStateAsync.when(
                            data: (state) {
                              final isPlaying = state.playing;
                              return GestureDetector(
                                onTap: () {
                                  if (isPlaying) {
                                    audioService.pause();
                                  } else {
                                    audioService.resume();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 30,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              );
                            },
                            loading: () => const SizedBox(
                              width: 30,
                              height: 30,
                              child: Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                            error: (_, __) => GestureDetector(
                              onTap: () => audioService.playAudio(audio.audioUrl),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  size: 30,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),

                          // Close / dismiss button
                          GestureDetector(
                            onTap: () {
                              audioService.stop();
                              ref.read(currentAudioProvider.notifier).state =
                                  null;
                              currentAudioNotifier.value = null;
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
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
          ),
        ),
      ),
    );
  }
}
