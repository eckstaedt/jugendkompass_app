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

// ─── Mini Player Bar ─────────────────────────────────────────────────────────

class MiniPlayerBar extends ConsumerWidget {
  final AudioModel audio;
  final GlobalKey<NavigatorState>? navigatorKey;

  const MiniPlayerBar({super.key, required this.audio, this.navigatorKey});

  void _openFullPlayer(BuildContext context) {
    final nav = navigatorKey?.currentState ?? Navigator.of(context);
    nav.push(
      PageRouteBuilder(
        settings: const RouteSettings(name: kFullPlayerRouteName),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => const FullPlayerScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioServiceProvider);
    final positionAsync = ref.watch(audioPositionProvider);
    final durationAsync = ref.watch(audioDurationProvider);
    final playerStateAsync = ref.watch(audioPlayerStateProvider);
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
                        error: (_, _) => const SizedBox.shrink(),
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
                            error: (_, _) => GestureDetector(
                              onTap: () => audioService.playAudio(audio.audioUrl, audio: audio),
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
