import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/utils/snackbar_utils.dart';
import 'package:jugendkompass_app/domain/providers/post_view_count_provider.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/data/models/read_history_item_model.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart' show currentAudioNotifier;
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/category_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/podcast_provider.dart';
import 'package:jugendkompass_app/domain/providers/read_history_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/widgets/common/skeleton_loading.dart';
import 'package:jugendkompass_app/presentation/widgets/common/animated_equalizer.dart';

class PodcastScreen extends ConsumerStatefulWidget {
  const PodcastScreen({super.key});

  @override
  ConsumerState<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends ConsumerState<PodcastScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final translate = ref.watch(stringTranslatorProvider);
    final audioListAsync = ref.watch(audioListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedPodcastCategoryProvider);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final textSecondary = DesignTokens.getTextSecondary(brightness);

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

              // Filter audio list based on selected category and search query
              List<AudioModel> filteredList;
              if (selectedCategory == null) {
                filteredList = List<AudioModel>.from(audioList);
              } else {
                filteredList = audioList.where((audio) {
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
              }

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                filteredList = filteredList.where((audio) {
                  final title = (audio.title ?? audio.post?.title ?? '').toLowerCase();
                  final description = (audio.description ?? '').toLowerCase();
                  return title.contains(_searchQuery) || description.contains(_searchQuery);
                }).toList();
              }

              // Sort by creation date (newest first), then by title alphabetically
              filteredList.sort((a, b) {
                final dateCompare = b.createdAt.compareTo(a.createdAt);
                if (dateCompare != 0) return dateCompare;
                // Secondary sort by title if same date
                final titleA = (a.title ?? a.post?.title ?? '').toLowerCase();
                final titleB = (b.title ?? b.post?.title ?? '').toLowerCase();
                return titleA.compareTo(titleB);
              });

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Text(
                        translate('Podcast'),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.getTextPrimary(brightness),
                        ),
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: RoundedCard(
                        glass: true,
                        backgroundColor: DesignTokens.glassBackgroundDeep(0.20),
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                        withShadow: false,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: translate('Podcasts suchen...'),
                            hintStyle: TextStyle(
                              color: textSecondary,
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: textSecondary,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: textSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
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

                  // Empty state when no podcasts match filter/search
                  if (filteredList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.podcasts_outlined,
                        title: translate('Keine Podcasts gefunden'),
                        message: _searchQuery.isNotEmpty
                            ? translate('Versuche eine andere Suche')
                            : translate('Keine Podcasts in dieser Kategorie'),
                      ),
                    ),

                  // Episode List
                  if (filteredList.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final audio = filteredList[index];
                        final currentAudio = ref.watch(currentAudioProvider);
                        final isActuallyPlaying = ref.watch(isPlayingProvider);
                        final isCurrentAndPlaying = currentAudio?.id == audio.id && isActuallyPlaying;

                        return _buildEpisodeListItem(
                          context,
                          ref,
                          audio,
                          isCurrentAndPlaying,
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

  String _formatViewCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  Widget _buildEpisodeListItem(
    BuildContext context,
    WidgetRef ref,
    AudioModel audio,
    bool isPlaying,
  ) {
    final theme = Theme.of(context);

    // Check if audio has been listened to
    final isListened = ref.watch(isContentReadProvider((id: audio.id, type: ReadContentType.audio)));

    return Opacity(
      opacity: isListened && !isPlaying ? 0.6 : 1.0,
      child: Card(
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
                          // View count tag
                          Consumer(
                            builder: (context, ref, _) {
                              final viewCountAsync = ref.watch(postViewCountProvider(audio.id));
                              return viewCountAsync.whenOrNull(
                                data: (count) => count == 0
                                    ? const SizedBox.shrink()
                                    : Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(DesignTokens.radiusBadges),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.visibility_outlined, size: 10, color: theme.colorScheme.onSecondaryContainer),
                                            const SizedBox(width: 3),
                                            Text(
                                              _formatViewCount(count),
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.onSecondaryContainer,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ) ?? const SizedBox.shrink();
                            },
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
              // Add to queue button
              IconButton(
                icon: const Icon(Icons.playlist_add),
                onPressed: () => _addToQueue(context, ref, audio),
                tooltip: 'Zur Warteschlange hinzufügen',
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _playAudio(BuildContext context, WidgetRef ref, AudioModel audio) async {
    final audioService = ref.read(audioServiceProvider);

    // Update providers immediately so the mini player bar appears instantly
    ref.read(audioQueueProvider.notifier).state = [audio];
    ref.read(currentQueueIndexProvider.notifier).state = 0;
    ref.read(currentAudioProvider.notifier).state = audio;
    currentAudioNotifier.value = audio;

    // Mark audio as listened
    ref.read(readHistoryProvider.notifier).markAsRead(
      audio.id,
      ReadContentType.audio,
      title: audio.title ?? audio.post?.title,
      imageUrl: audio.imageUrl,
    );

    // Start playback (setQueue calls playAudio internally)
    await audioService.setQueue([audio], startIndex: 0);
  }

  void _addToQueue(BuildContext context, WidgetRef ref, AudioModel audio) {
    final audioService = ref.read(audioServiceProvider);
    final translate = ref.read(stringTranslatorProvider);

    audioService.addToQueue(audio);
    ref.read(audioQueueProvider.notifier).state = List<AudioModel>.from(audioService.queue);

    SnackBarUtils.show(
      context,
      '${audio.title ?? audio.post?.title ?? "Audio"} ${translate('zur Warteschlange hinzugefügt')}',
      duration: const Duration(seconds: 2),
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
