import 'package:jugendkompass_app/core/localization/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/post_provider.dart';
import 'package:jugendkompass_app/domain/providers/video_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/impulse_provider.dart';
import 'package:jugendkompass_app/domain/providers/message_provider.dart';
import 'package:jugendkompass_app/domain/providers/edition_provider.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart' show currentAudioNotifier, kVideoPlayerRouteName;
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/screens/post/post_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/presentation/screens/impulse/impulse_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/message/message_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/edition_detail_screen.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/utils/html_utils.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

// Combined content item for unified display
class _CombinedContentItem {
  final String id;
  final String title;
  final String? imageUrl;
  final String contentType; // VIDEO, ARTIKEL, IMPULS, KURZNACHRICHT, AUSGABE
  final bool hasAudio; // Whether the article has audio
  final dynamic data; // Original data (Post, Video, etc.)
  final String searchText; // title + body/description for full-text search
  final DateTime date;

  _CombinedContentItem({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.contentType,
    this.hasAudio = false,
    required this.data,
    String? searchText,
    required this.date,
  }) : searchText = searchText ?? title;
}

final _selectedDiscoverFilterProvider = StateProvider<String>((ref) => 'alle');
final _sortDescendingProvider = StateProvider<bool>((ref) => true);

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
    final sortDescending = ref.watch(_sortDescendingProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('search'.tr),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
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

            // Filter Chips + Sort
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildFilterChip('Alle', 'alle', selectedFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('Artikel', 'artikel', selectedFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('Video', 'video', selectedFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('Audio', 'audio', selectedFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('Impuls', 'impuls', selectedFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('Kurznachricht', 'kurznachricht', selectedFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('Ausgabe', 'ausgabe', selectedFilter),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                      color: DesignTokens.primaryRed,
                    ),
                    tooltip: sortDescending ? 'Neueste zuerst' : 'Älteste zuerst',
                    onPressed: () {
                      ref.read(_sortDescendingProvider.notifier).state = !sortDescending;
                    },
                  ),
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
    final impulsesAsync = ref.watch(dailyImpulsesProvider);
    final messagesAsync = ref.watch(messagesListProvider);
    final editionsAsync = ref.watch(editionsListProvider);
    final sortDescending = ref.watch(_sortDescendingProvider);

    if (postsAsync.isLoading || videosAsync.isLoading ||
        impulsesAsync.isLoading || messagesAsync.isLoading || editionsAsync.isLoading) {
      return LoadingIndicator(message: AppTranslations.t('loading_content'));
    }

    if (postsAsync.hasError) {
      return Center(child: Text(AppTranslations.t('error_loading')));
    }

    final posts = postsAsync.value ?? [];
    final videos = videosAsync.value ?? [];
    final impulses = impulsesAsync.value ?? [];
    final messages = messagesAsync.value ?? [];
    final editions = editionsAsync.value ?? [];

    List<_CombinedContentItem> combinedItems = [];

    // Posts / Artikel
    for (var post in posts) {
      bool shouldAdd = filter == 'alle' ||
          (filter == 'artikel' && post.audioId == null) ||
          (filter == 'audio' && post.audioId != null);
      if (shouldAdd) {
        combinedItems.add(_CombinedContentItem(
          id: post.id,
          title: HtmlUtils.stripHtml(post.title),
          imageUrl: post.imageUrl,
          contentType: post.audioId != null ? 'AUDIO' : 'ARTIKEL',
          hasAudio: post.audioId != null,
          data: post,
          date: post.createdAt,
          searchText: '${HtmlUtils.stripHtml(post.title)} ${HtmlUtils.stripHtml(post.body)}',
        ));
      }
    }

    // Videos
    if (filter == 'alle' || filter == 'video') {
      for (var video in videos) {
        combinedItems.add(_CombinedContentItem(
          id: video.id,
          title: HtmlUtils.stripHtml(video.displayTitle),
          imageUrl: video.thumbnailUrl,
          contentType: 'VIDEO',
          data: video,
          date: video.createdAt,
          searchText: '${HtmlUtils.stripHtml(video.displayTitle)} ${HtmlUtils.stripHtml(video.description ?? "")}',
        ));
      }
    }

    // Impulse
    if (filter == 'alle' || filter == 'impuls') {
      for (var impulse in impulses) {
        combinedItems.add(_CombinedContentItem(
          id: impulse.id,
          title: HtmlUtils.stripHtml(impulse.displayTitle),
          imageUrl: impulse.imageUrl,
          contentType: 'IMPULS',
          data: impulse,
          date: impulse.date,
          searchText: '${HtmlUtils.stripHtml(impulse.displayTitle)} ${HtmlUtils.stripHtml(impulse.impulseText)}',
        ));
      }
    }

    // Kurznachrichten
    if (filter == 'alle' || filter == 'kurznachricht') {
      for (var message in messages) {
        combinedItems.add(_CombinedContentItem(
          id: message.id,
          title: HtmlUtils.stripHtml(message.displayTitle),
          imageUrl: message.imageUrl,
          contentType: 'KURZNACHRICHT',
          data: message,
          date: message.createdAt,
          searchText: '${HtmlUtils.stripHtml(message.displayTitle)} ${HtmlUtils.stripHtml(message.message)}',
        ));
      }
    }

    // Ausgaben
    if (filter == 'alle' || filter == 'ausgabe') {
      for (var edition in editions) {
        combinedItems.add(_CombinedContentItem(
          id: edition.id,
          title: HtmlUtils.stripHtml(edition.displayTitle),
          imageUrl: edition.coverImageUrl,
          contentType: 'AUSGABE',
          data: edition,
          date: edition.publishedDate,
          searchText: HtmlUtils.stripHtml(edition.displayTitle),
        ));
      }
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      combinedItems = combinedItems.where((item) {
        return item.searchText.toLowerCase().contains(query);
      }).toList();
    }

    // Sort by date
    combinedItems.sort((a, b) => sortDescending
        ? b.date.compareTo(a.date)
        : a.date.compareTo(b.date));

    if (combinedItems.isEmpty) {
      return EmptyState(
        icon: Icons.explore_outlined,
        title: AppTranslations.t('no_content_found'),
        message: AppTranslations.t('try_different_filter'),
      );
    }

    return Consumer(
      builder: (context, ref, _) {
        final hasAudio = ref.watch(currentAudioProvider) != null;
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(20, 8, 20,
            hasAudio
                ? DesignTokens.overlayPaddingWithMiniPlayer
                : DesignTokens.overlayPaddingBase),
          itemCount: combinedItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildContentTile(context, combinedItems[index]);
          },
        );
      },
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
      case 'IMPULS':
        return Icons.lightbulb_outline;
      case 'KURZNACHRICHT':
        return Icons.message_outlined;
      case 'AUSGABE':
        return Icons.menu_book_outlined;
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
      case 'IMPULS':
        return Colors.orange;
      case 'KURZNACHRICHT':
        return Colors.blue;
      case 'AUSGABE':
        return Colors.purple;
      case 'ARTIKEL':
      default:
        return DesignTokens.getTextSecondary(Theme.of(context).brightness);
    }
  }

  void _handleItemTap(_CombinedContentItem item) async {
    if (item.contentType == 'VIDEO') {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: kVideoPlayerRouteName),
            builder: (context) => VideoPlayerScreen(
              videoUrl: item.data.videoUrl,
              title: item.data.displayTitle,
              description: item.data.description,
              imageUrl: item.data.imageUrl,
            ),
          ),
        );
      }
    } else if (item.contentType == 'IMPULS') {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImpulseDetailScreen(impulse: item.data),
          ),
        );
      }
    } else if (item.contentType == 'KURZNACHRICHT') {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageDetailScreen(message: item.data),
          ),
        );
      }
    } else if (item.contentType == 'AUSGABE') {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditionDetailScreen(edition: item.data),
          ),
        );
      }
    } else if (item.hasAudio && item.data.audioId != null) {
      await _playAudio(item.data);
    } else {
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

      // Update providers immediately so the mini player bar appears instantly
      ref.read(audioQueueProvider.notifier).state = [audio];
      ref.read(currentQueueIndexProvider.notifier).state = 0;
      ref.read(currentAudioProvider.notifier).state = audio;
      currentAudioNotifier.value = audio;

      // Start playback (setQueue calls playAudio internally)
      final audioService = ref.read(audioServiceProvider);
      await audioService.setQueue([audio], startIndex: 0);

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
