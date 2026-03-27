import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/domain/providers/video_provider.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart'
    show kVideoPlayerRouteName;
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';

class VideoScreen extends ConsumerStatefulWidget {
  const VideoScreen({super.key});

  @override
  ConsumerState<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends ConsumerState<VideoScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(videosListProvider);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final textPrimary = DesignTokens.getTextPrimary(brightness);
    final textSecondary = DesignTokens.getTextSecondary(brightness);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Videos',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ),

            // Search Bar at Top
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                    hintText: 'Videos suchen...',
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

            // Videos List
            Expanded(
              child: videosAsync.when(
                data: (videos) {
                  // Sort videos by createdAt descending (newest first)
                  final sortedVideos = videos..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  // Filter by search query
                  final filteredVideos = _searchQuery.isEmpty
                      ? sortedVideos
                      : sortedVideos.where((video) =>
                          video.title.toLowerCase().contains(_searchQuery) ||
                          (video.description?.toLowerCase().contains(_searchQuery) ?? false)).toList();

                  if (filteredVideos.isEmpty) {
                    return EmptyState(
                      icon: Icons.video_library_outlined,
                      title: 'Keine Videos gefunden',
                      message: 'Versuche eine andere Suche',
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: filteredVideos.length,
                    itemBuilder: (context, index) {
                      final video = filteredVideos[index];
                      return VideoCard(
                        video: video,
                      );
                    },
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (error, stack) => Center(
                  child: Text('Fehler: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoCard extends ConsumerStatefulWidget {
  final dynamic video; // VideoModel

  const VideoCard({super.key, required this.video});

  @override
  ConsumerState<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends ConsumerState<VideoCard> {
  VideoPlayerController? _videoPlayerController;
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    _loadDuration();
  }

  Future<void> _loadDuration() async {
    if (widget.video.duration != null && widget.video.duration! > 0) {
      if (mounted) {
        setState(() => _duration = widget.video.duration!);
      }
      return;
    }

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.url),
      );
      await _videoPlayerController!.initialize();
      final durationMs = _videoPlayerController!.value.duration.inSeconds;
      
      if (mounted) {
        setState(() => _duration = durationMs);
      }
      
      await _videoPlayerController?.dispose();
      _videoPlayerController = null;
    } catch (e) {
      // Dauer konnte nicht geladen werden
      _videoPlayerController = null;
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '';
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds.remainder(60);
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Heute';
    } else if (difference.inDays == 1) {
      return 'Gestern';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays} Tagen';
    } else if (difference.inDays < 30) {
      return 'vor ${(difference.inDays / 7).floor()} Wochen';
    } else {
      return DateFormat('d. MMM yyyy', 'de_DE').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: kVideoPlayerRouteName),
            builder: (context) => VideoPlayerScreen(
              videoUrl: widget.video.url,
              title: widget.video.title,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // YouTube-style Thumbnail (16:9 aspect ratio)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail Image
                  widget.video.imageUrl != null
                      ? CorsNetworkImage(
                          imageUrl: widget.video.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: DesignTokens.glassBackground(0.3),
                          child: const Icon(Icons.video_library, size: 48),
                        ),

                  // Duration Badge (bottom right) - only show if duration > 0
                  if (_duration > 0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          _formatDuration(_duration),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Play Icon (center)
                  Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white.withOpacity(0.8),
                      size: 48,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Video Title
          Text(
            widget.video.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.getTextPrimary(Theme.of(context).brightness),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Upload Date
          Text(
            _formatDate(widget.video.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: DesignTokens.getTextSecondary(Theme.of(context).brightness),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}