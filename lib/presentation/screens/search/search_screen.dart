import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/post_provider.dart';
import 'package:jugendkompass_app/domain/providers/video_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/screens/post/post_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

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
    final selectedFilter = ref.watch(_selectedDiscoverFilterProvider);

    return Scaffold(
      backgroundColor: DesignTokens.appBackground,
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
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Wonach suchst du?',
                      hintStyle: TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: DesignTokens.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey.shade500),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusInputFields),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
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
      backgroundColor: Colors.white,
      selectedColor: DesignTokens.primaryRed,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : DesignTokens.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 14,
      ),
      side: BorderSide(
        color: isSelected ? DesignTokens.primaryRed : Colors.grey.shade300,
        width: 1,
      ),
      checkmarkColor: Colors.white,
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
                  title: post.title,
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
                  title: video.displayTitle,
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
              return const EmptyState(
                icon: Icons.explore_outlined,
                title: 'Keine Inhalte gefunden',
                message: 'Versuche einen anderen Filter oder Suchbegriff',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: combinedItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildContentTile(combinedItems[index]);
              },
            );
          },
          loading: () => const LoadingIndicator(message: 'Lade Videos...'),
          error: (error, stack) => const LoadingIndicator(message: 'Lade Inhalte...'),
        );
      },
      loading: () => const LoadingIndicator(message: 'Lade Inhalte...'),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
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

  Widget _buildContentTile(_CombinedContentItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => _handleItemTap(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
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

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                                    color: DesignTokens.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Badges Row
                    Row(
                      children: [
                        // Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(item.contentType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
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
                        // Audio Badge if article has audio
                        if (item.hasAudio) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                                          color: DesignTokens.successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
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
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
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
        return DesignTokens.textSecondary;
    }
  }

  void _handleItemTap(_CombinedContentItem item) async {
    if (item.contentType == 'VIDEO') {
      // Play video
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
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
            const SnackBar(
              content: Text('Audio nicht gefunden'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Set as current audio
      ref.read(currentAudioProvider.notifier).state = audio;

      // Play the audio
      final audioService = ref.read(audioServiceProvider);
      await audioService.playAudio(audio.url);

      // Don't navigate to full player - let the mini player bar handle it
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Abspielen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
