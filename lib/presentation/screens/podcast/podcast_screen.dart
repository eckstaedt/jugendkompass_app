import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/podcast_provider.dart';
import 'package:jugendkompass_app/domain/providers/category_provider.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';
import 'widgets/featured_episode_card.dart';
import 'full_player_screen.dart';

class PodcastScreen extends ConsumerWidget {
  const PodcastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioListAsync = ref.watch(audioListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedPodcastCategoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: DesignTokens.appBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(audioListProvider);
          },
          child: audioListAsync.when(
            data: (audioList) {
              if (audioList.isEmpty) {
                return const EmptyState(
                  icon: Icons.podcasts_outlined,
                  title: 'Keine Podcasts verfügbar',
                  message: 'Es sind noch keine Podcast-Episoden vorhanden.',
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
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                      child: RoundedCard(
                        glass: true,
                        backgroundColor: DesignTokens.glassBackgroundDeep(0.20),
                        padding: const EdgeInsets.all(16),
                        withShadow: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Podcast',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: DesignTokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Alle Episoden',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: DesignTokens.textSecondary,
                              ),
                            ),
                          ],
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
                                  label: const Text('Alle'),
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
                                  backgroundColor: Colors.white,
                                  selectedColor: DesignTokens.primaryRed,
                                  labelStyle: TextStyle(
                                    color: selectedCategory == null
                                      ? Colors.white
                                      : DesignTokens.textSecondary,
                                    fontWeight: selectedCategory == null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  side: BorderSide(
                                    color: selectedCategory == null
                                      ? DesignTokens.primaryRed
                                      : const Color(0xFFE5E7EB),
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
                                    backgroundColor: Colors.white,
                                    selectedColor: DesignTokens.primaryRed,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : DesignTokens.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    side: BorderSide(
                                      color: isSelected
                                          ? DesignTokens.primaryRed
                                          : const Color(0xFFE5E7EB),
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
                    loading: () => const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 60,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (error, stack) =>
                        const SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),

                  // Featured Episode
                  if (featuredEpisode != null)
                    SliverToBoxAdapter(
                      child: FeaturedEpisodeCard(
                        audio: featuredEpisode,
                        onPlay: () => _playAudio(context, ref, featuredEpisode),
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
                          color: DesignTokens.textPrimary,
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

                  // Bottom spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80), // Extra space for mini player
                  ),
                ],
              );
            },
            loading: () => const LoadingIndicator(message: 'Lade Podcasts...'),
            error: (error, stack) => ErrorView(
              message: 'Fehler beim Laden der Podcasts: $error',
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: audio.imageUrl != null
              ? CachedNetworkImage(
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
              : Container(
                  width: 60,
                  height: 60,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.podcasts),
                ),
        ),
        title: Text(
          // Title comes from the linked post
          audio.title ?? audio.post?.title ?? 'Unbekannter Titel',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Category badges
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play button or playing indicator
            if (isPlaying)
              Icon(Icons.graphic_eq, color: theme.colorScheme.primary)
            else
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                iconSize: 32,
                onPressed: () => _playAudio(context, ref, audio),
              ),
          ],
        ),
        onTap: () => _playAudio(context, ref, audio),
      ),
    );
  }

  void _playAudio(BuildContext context, WidgetRef ref, AudioModel audio) {
    final audioService = ref.read(audioServiceProvider);

    // Set single audio as queue with only one item
    audioService.setQueue([audio], startIndex: 0);

    // Update providers
    ref.read(audioQueueProvider.notifier).state = [audio];
    ref.read(currentQueueIndexProvider.notifier).state = 0;
    ref.read(currentAudioProvider.notifier).state = audio;

    // Navigate to full player
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FullPlayerScreen()),
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
