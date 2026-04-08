import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart' show currentAudioNotifier;
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/category_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/podcast_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/widgets/common/skeleton_loading.dart';
import 'package:jugendkompass_app/presentation/widgets/common/animated_equalizer.dart';
import 'widgets/featured_episode_card.dart';

class PodcastScreen extends ConsumerWidget {
  const PodcastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final translate = ref.watch(stringTranslatorProvider);
    final audioListAsync = ref.watch(audioListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedPodcastCategoryProvider);
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(audioListProvider);
          },
          child: audioListAsync.when(
            data: (audioList) {
              if (audioList.isEmpty) {
                return EmptyState(
                  icon: Icons.podcasts_outlined,
                  title: translate('Keine Podcasts verfügbar'),
                  message: translate('Es sind noch keine Podcast-Episoden vorhanden.'),
                );
              }

              // Filter audio list based on selected category
              final filteredList = selectedCategory == null
                  ? audioList
                      : audioList.where((audio) {
                        // Get list of category names from post (support multi tags)
                        final post = audio.post;
                        if (post == null) return false;
                        final categories = post.categoryNames ??
                          (post.categoryName != null ? [post.categoryName!] : []);
                        if (categories.isEmpty) return false;

                        final normalizedSelectedCategory = selectedCategory
                          .toLowerCase()
                          .replaceAll(' ', '_');

                        // check any tag matches
                        return categories.any((categoryName) {
                        final normalizedPostCategory = categoryName
                          .toLowerCase()
                          .replaceAll(' ', '_');
                        return normalizedPostCategory == normalizedSelectedCategory;
                        });
                      }).toList();

              // Get featured episode (first in list)
              final featuredEpisode = audioList.isNotEmpty
                  ? audioList.first
                  : null;

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Text(
                        'Podcast',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.getTextPrimary(brightness),
                        ),
                      ),
                    ),
                  ),

                  // Filter Chips
                  categoriesAsync.when(
                    data: (categories) {
                      return SliverToBoxAdapter(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              // "Alle" chip
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(AppTranslations.t('all_filter')),
                                  selected: selectedCategory == null,
                                  onSelected: (_) {
                                    ref
                                            .read(
                                              selectedPodcastCategoryProvider
                                                  .notifier,
                                            )
                                            .state =
                                        null;
                                  },
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  selectedColor: DesignTokens.primaryRed,
                                  labelStyle: TextStyle(
                                    color: selectedCategory == null
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : DesignTokens.getTextSecondary(brightness),
                                    fontWeight: selectedCategory == null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  side: BorderSide(
                                    color: selectedCategory == null
                                      ? DesignTokens.primaryRed
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.12),
                                    width: 1.5,
                                  ),
                                    checkmarkColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              // Category chips from database
                              ...categories.map((category) {
                                final categoryKey = category.name
                                    .toLowerCase()
                                    .replaceAll(' ', '_');
                                final isSelected =
                                    selectedCategory == categoryKey;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(category.name),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      ref
                                              .read(
                                                selectedPodcastCategoryProvider
                                                    .notifier,
                                              )
                                              .state =
                                          categoryKey;
                                    },
                                    backgroundColor: DesignTokens.getCardBackground(brightness),
                                    selectedColor: DesignTokens.primaryRed,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : DesignTokens.getTextSecondary(brightness),
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    side: BorderSide(
                                      color: isSelected
                                          ? DesignTokens.primaryRed
                                          : (brightness == Brightness.dark
                                              ? Colors.grey.shade700
                                              : const Color(0xFFE5E7EB)),
                                      width: 1.5,
                                    ),
                                    checkmarkColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => SliverToBoxAdapter(
                      child: SkeletonShimmer(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Row(
                            children: List.generate(
                              4,
                              (_) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: SkeletonBox(width: 70, height: 32, radius: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    error: (error, stack) =>
                        const SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),

                  // Featured Episode
                  if (featuredEpisode != null)
                    SliverToBoxAdapter(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final currentAudio = ref.watch(currentAudioProvider);
                          final isFeaturedPlaying = currentAudio?.id == featuredEpisode.id;
                          return FeaturedEpisodeCard(
                            audio: featuredEpisode,
                            isPlaying: isFeaturedPlaying,
                            onPlay: () => _playAudio(context, ref, featuredEpisode),
                          );
                        },
                      ),
                    ),

                  // "ALLE FOLGEN" Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'ALLE FOLGEN',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: DesignTokens.getTextPrimary(brightness),
                        ),
                      ),
                    ),
                  ),

                  // Episode List
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final audio = filteredList[index];
                      final currentAudio = ref.watch(currentAudioProvider);
                      final isPlaying = currentAudio?.id == audio.id;

                      return _buildEpisodeListItem(
                        context,
                        ref,
                        audio,
                        isPlaying,
                      );
                    }, childCount: filteredList.length),
                  ),

                  // Bottom spacing: add extra height when the mini player
                  // bar is visible so the last item is not hidden behind it.
                  SliverToBoxAdapter(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final hasAudio =
                            ref.watch(currentAudioProvider) != null;
                        return SizedBox(
                            height: hasAudio
                                ? DesignTokens.overlayPaddingWithMiniPlayer
                                : DesignTokens.overlayPaddingBase);
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const PodcastListSkeleton(),
            error: (error, stack) => ErrorView(
              message: '${translate('Fehler beim Laden der Podcasts')}: $error',
              onRetry: () => ref.invalidate(audioListProvider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeListItem(
    BuildContext context,
    WidgetRef ref,
    AudioModel audio,
    bool isPlaying,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // Tapping anywhere on the tile plays the audio instantly
        onTap: () => _playAudio(context, ref, audio),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (audio.imageUrl != null)
                          CachedNetworkImage(
                            imageUrl: audio.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 60,
                              height: 60,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 60,
                              height: 60,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.podcasts),
                            ),
                          )
                        else
                          Container(
                            width: 60,
                            height: 60,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.podcasts),
                          ),
                        // Play overlay
                        if (!isPlaying)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        // Equaliser when playing
                        if (isPlaying)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                            ),
                            child: Center(
                              child: AnimatedEqualizer(
                                color: DesignTokens.primaryRed,
                                size: 28,
                                barCount: 3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ),
              const SizedBox(width: 12),
              // Title + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audio.title ?? audio.post?.title ?? 'Unbekannter Titel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (audio.post != null)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          for (var tag in audio.post!.categoryNames ??
                              (audio.post!.categoryName != null
                                  ? [audio.post!.categoryName!]
                                  : []))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: DesignTokens.primaryRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    DesignTokens.radiusBadges),
                              ),
                              child: Text(
                                tag,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: DesignTokens.primaryRed,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    if (audio.durationSeconds != null) ...[  
                      const SizedBox(height: 6),
                      Text(
                        _formatDuration(audio.durationSeconds!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }  Future<void> _playAudio(BuildContext context, WidgetRef ref, AudioModel audio) async {
    final audioService = ref.read(audioServiceProvider);

    // Update providers immediately so the mini player bar appears instantly
    ref.read(audioQueueProvider.notifier).state = [audio];
    ref.read(currentQueueIndexProvider.notifier).state = 0;
    ref.read(currentAudioProvider.notifier).state = audio;
    currentAudioNotifier.value = audio;

    // Start playback (setQueue calls playAudio internally)
    await audioService.setQueue([audio], startIndex: 0);
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
