import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/podcast_provider.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'widgets/featured_episode_card.dart';
import 'full_player_screen.dart';

class PodcastScreen extends ConsumerWidget {
  const PodcastScreen({super.key});

  // Podcast categories for filtering
  static const List<Map<String, String>> categories = [
    {'id': 'all', 'label': 'Alle'},
    {'id': 'glaube', 'label': 'Glaube'},
    {'id': 'deep_dive', 'label': 'Deep Dive'},
    {'id': 'lifestyle', 'label': 'Lifestyle'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioListAsync = ref.watch(audioListProvider);
    final selectedCategory = ref.watch(selectedPodcastCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcast'),
      ),
      body: RefreshIndicator(
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
            final filteredList = selectedCategory == null || selectedCategory == 'all'
                ? audioList
                : audioList.where((audio) {
                    // TODO: Implement proper category filtering based on your data
                    return true; // For now, show all
                  }).toList();

            // Get featured episode (first in list)
            final featuredEpisode = audioList.isNotEmpty ? audioList.first : null;


            return CustomScrollView(
              slivers: [
                // Filter Chips
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: categories.map((category) {
                        final isSelected = selectedCategory == category['id'] ||
                            (selectedCategory == null && category['id'] == 'all');
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category['label']!),
                            selected: isSelected,
                            onSelected: (_) {
                              ref.read(selectedPodcastCategoryProvider.notifier).state =
                                  category['id'] == 'all' ? null : category['id'];
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF8B3A3A),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF6B7280),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF8B3A3A)
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
                      }).toList(),
                    ),
                  ),
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Color(0xFF8B3A3A),
                      ),
                    ),
                  ),
                ),

                // Episode List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final audio = filteredList[index];
                      final currentAudio = ref.watch(currentAudioProvider);
                      final isPlaying = currentAudio?.id == audio.id;

                      return _buildEpisodeListItem(
                        context,
                        ref,
                        audio,
                        isPlaying,
                      );
                    },
                    childCount: filteredList.length,
                  ),
                ),

                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80), // Extra space for mini player
                ),
              ],
            );
          },
          loading: () => const LoadingIndicator(
            message: 'Lade Podcasts...',
          ),
          error: (error, stack) => ErrorView(
            message: 'Fehler beim Laden der Podcasts: $error',
            onRetry: () => ref.invalidate(audioListProvider),
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
            if (audio.description != null || audio.post?.body != null) ...[
              const SizedBox(height: 4),
              Html(
                data: audio.description ?? audio.post?.body ?? '',
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(theme.textTheme.bodySmall?.fontSize ?? 12),
                    maxLines: 2,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                  "p": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(theme.textTheme.bodySmall?.fontSize ?? 12),
                    maxLines: 2,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                },
              ),
            ],
            if (audio.durationSeconds != null) ...[
              const SizedBox(height: 4),
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
            // Show info icon if post is accessible
            if (audio.post != null)
              IconButton(
                icon: const Icon(Icons.info_outline),
                iconSize: 20,
                onPressed: () {
                  // Access the linked post directly
                  final post = audio.post!;
                  // TODO: Navigate to post detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Post: ${post.title}\nID: ${post.id}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            // Play button or playing indicator
            if (isPlaying)
              Icon(
                Icons.graphic_eq,
                color: theme.colorScheme.primary,
              )
            else
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                onPressed: () => _playAudio(context, ref, audio),
              ),
          ],
        ),
        onTap: () => _playAudio(context, ref, audio),
      ),
    );
  }

  void _playAudio(BuildContext context, WidgetRef ref, AudioModel audio) {
    // Set current audio
    ref.read(currentAudioProvider.notifier).state = audio;

    // Play audio
    final audioService = ref.read(audioServiceProvider);
    audioService.playAudio(audio.audioUrl);

    // Navigate to full player
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FullPlayerScreen(),
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
