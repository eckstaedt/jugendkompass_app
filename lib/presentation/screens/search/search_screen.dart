import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/post_provider.dart';
import 'package:jugendkompass_app/domain/providers/video_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart' show currentAudioNotifier, kVideoPlayerRouteName;
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/screens/post/post_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/utils/html_utils.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

// Combined content item for unified display
class _CombinedContentItem {
  final String id;
  final String title;
  final String? imageUrl;
  final String contentType; // VIDEO, ARTIKEL
  final bool hasAudio; // Whether the article has audio
  final dynamic data; // Original data (Post, Video, etc.)

  _CombinedContentItem({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.contentType,
    this.hasAudio = false,
    required this.data,
  });
}

final _selectedDiscoverFilterProvider = StateProvider<String>((ref) => 'alle');

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final textPrimary = DesignTokens.getTextPrimary(brightness);
    final textSecondary = DesignTokens.getTextSecondary(brightness);
    final selectedFilter = ref.watch(_selectedDiscoverFilterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Suche'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Entdecken',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Field
                  // search box sits inside a glass card to match app style
                  RoundedCard(
                    glass: true,
                    backgroundColor: DesignTokens.glassBackgroundDeep(0.20),
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    withShadow: false,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                      hintText: 'Wonach suchst du?',
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
                            icon: Icon(Icons.clear,
                              color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusInputFields),
                        borderSide: BorderSide(
                            color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusInputFields),
                        borderSide: const BorderSide(
                          color: DesignTokens.primaryRed,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                  ), // close RoundedCard
                ],
              ),
            ),

            // Filter Chips
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildFilterChip('Für Dich', 'für_dich', selectedFilter),
                  const SizedBox(width: 8),
                  _buildFilterChip('Alle', 'alle', selectedFilter),
                  const SizedBox(width: 8),
                  _buildFilterChip('Video', 'video', selectedFilter),
                  const SizedBox(width: 8),
                  _buildFilterChip('Audio', 'audio', selectedFilter),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Content List
            Expanded(
              child: _buildContentList(selectedFilter),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedFilter) {
    final isSelected = selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(_selectedDiscoverFilterProvider.notifier).state = value;
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: DesignTokens.primaryRed,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : DesignTokens.getTextSecondary(Theme.of(context).brightness),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 14,
      ),
      side: BorderSide(
        color: isSelected
            ? DesignTokens.primaryRed
            : Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.12),
        width: 1,
      ),
      checkmarkColor: Theme.of(context).colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildContentList(String filter) {
    // Load all posts with default filter
    final defaultFilter = PostFilter(limit: 100);
    final postsAsync = ref.watch(postsListProvider(defaultFilter));
    final videosAsync = ref.watch(videosListProvider);

    return postsAsync.when(
      data: (posts) {
        return videosAsync.when(
          data: (videos) {
            // Combine posts and videos into a unified list
            List<_CombinedContentItem> combinedItems = [];

            // Add posts (all posts are shown as ARTIKEL, with hasAudio flag if they have audio)
            for (var post in posts) {
              // Apply filter
              bool shouldAdd = false;
              if (filter == 'alle' || filter == 'für_dich') {
                shouldAdd = true;
              } else if (filter == 'audio' && post.audioId != null) {
                shouldAdd = true;
              }

              if (shouldAdd) {
                combinedItems.add(_CombinedContentItem(
                  id: post.id,
                  title: HtmlUtils.stripHtml(post.title),
                  imageUrl: post.imageUrl,
                  contentType: 'ARTIKEL',
                  hasAudio: post.audioId != null,
                  data: post,
                ));
              }
            }

            // Add videos
            for (var video in videos) {
              // Apply filter
              if (filter == 'alle' || filter == 'für_dich' || filter == 'video') {
                combinedItems.add(_CombinedContentItem(
                  id: video.id,
                  title: HtmlUtils.stripHtml(video.displayTitle),
                  imageUrl: video.thumbnailUrl,
                  contentType: 'VIDEO',
                  hasAudio: false,
                  data: video,
                ));
              }
            }

            // Apply search filter
            if (_searchQuery.isNotEmpty) {
              combinedItems = combinedItems.where((item) {
                return item.title.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();
            }

            if (combinedItems.isEmpty) {
              return EmptyState(
                icon: Icons.explore_outlined,
                title: AppTranslations.t('no_content_found'),
                message: AppTranslations.t('try_different_filter'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: combinedItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildContentTile(context, combinedItems[index]);
              },
            );
          },
          loading: () => LoadingIndicator(message: AppTranslations.t('loading_videos')),
          error: (error, stack) => LoadingIndicator(message: AppTranslations.t('loading_content')),
        );
      },
      loading: () => LoadingIndicator(message: AppTranslations.t('loading_content')),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              AppTranslations.t('error_loading'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTile(BuildContext context, _CombinedContentItem item) {
    final brightness = Theme.of(context).brightness;
    final textPrimary = DesignTokens.getTextPrimary(brightness);
    final textSecondary = DesignTokens.getTextSecondary(brightness);
    final cardBg = DesignTokens.getGlassBackground(brightness, 0.20);
    // rebuild clean version to avoid mismatched brackets
    return RoundedCard(
      glass: true,
      backgroundColor: cardBg,
      padding: const EdgeInsets.all(12),
      withShadow: false,
      child: InkWell(
        onTap: () => _handleItemTap(item),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Image/Thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getTypeColor(item.contentType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusInputFields),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? CorsNetworkImage(
                        imageUrl: item.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        _getTypeIcon(item.contentType),
                        color: _getTypeColor(item.contentType),
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Content description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Badges row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(item.contentType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusBadges),
                        ),
                        child: Text(
                          item.contentType,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getTypeColor(item.contentType),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (item.hasAudio)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusBadges),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.headphones,
                                size: 11,
                                color: DesignTokens.successGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'AUDIO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: DesignTokens.successGreen,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron icon
            Icon(
              Icons.chevron_right,
              color: textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'AUDIO':
        return Icons.headphones_rounded;
      case 'VIDEO':
        return Icons.play_circle_outline;
      case 'ARTIKEL':
      default:
        return Icons.article_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'AUDIO':
        return DesignTokens.successGreen;
      case 'VIDEO':
        return DesignTokens.primaryRed;
      case 'ARTIKEL':
      default:
        return DesignTokens.getTextSecondary(Theme.of(context).brightness);
    }
  }

  void _handleItemTap(_CombinedContentItem item) async {
    if (item.contentType == 'VIDEO') {
      // Play video
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: kVideoPlayerRouteName),
            builder: (context) => VideoPlayerScreen(
              videoUrl: item.data.videoUrl,
              title: item.data.displayTitle,
            ),
          ),
        );
      }
    } else if (item.hasAudio && item.data.audioId != null) {
      // Play audio - don't navigate, just play and show mini player
      await _playAudio(item.data);
    } else {
      // Navigate to post detail (ARTIKEL without audio)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: item.data),
          ),
        );
      }
    }
  }

  Future<void> _playAudio(dynamic post) async {
    if (post.audioId == null) return;

    try {
      final audioRepository = ref.read(audioRepositoryProvider);
      final audio = await audioRepository.getAudioById(post.audioId!);

      if (audio == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTranslations.t('audio_not_found')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Set queue + current audio so the mini player bar and full player work.
      final audioService = ref.read(audioServiceProvider);
      await audioService.setQueue([audio], startIndex: 0);
      ref.read(audioQueueProvider.notifier).state = [audio];
      ref.read(currentQueueIndexProvider.notifier).state = 0;
      ref.read(currentAudioProvider.notifier).state = audio;
      currentAudioNotifier.value = audio;

      // Start playback
      await audioService.playAudio(audio.url);

      // Don't navigate to full player - let the mini player bar handle it
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslations.t('error_playing')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
