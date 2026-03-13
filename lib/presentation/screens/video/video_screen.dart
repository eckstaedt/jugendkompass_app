import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/video_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';
import 'package:intl/intl.dart';

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
    final theme = Theme.of(context);
    final videosAsync = ref.watch(videosListProvider);

    return Scaffold(
      backgroundColor: DesignTokens.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar at Top
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                      color: DesignTokens.textSecondary,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: DesignTokens.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: DesignTokens.textSecondary),
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
                    return const EmptyState(
                      icon: Icons.video_library_outlined,
                      title: 'Keine Videos gefunden',
                      message: 'Versuche eine andere Suche',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredVideos.length,
                    itemBuilder: (context, index) {
                      final video = filteredVideos[index];
                      final isNew = video.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: VideoCard(
                          video: video,
                          isNew: isNew,
                        ),
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

class VideoCard extends StatelessWidget {
  final dynamic video; // VideoModel
  final bool isNew;

  const VideoCard({super.key, required this.video, required this.isNew});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoUrl: video.url,
              title: video.title,
            ),
          ),
        );
      },
      child: RoundedCard(
        glass: true,
        backgroundColor: DesignTokens.glassBackground(0.08),
        padding: const EdgeInsets.all(12),
        withShadow: true,
        child: Row(
          children: [
            // Video Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
              child: SizedBox(
                width: 120,
                height: 68,
                child: video.imageUrl != null
                    ? CorsNetworkImage(
                        imageUrl: video.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: DesignTokens.glassBackground(0.2),
                        child: const Icon(Icons.video_library, size: 32),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Video Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    video.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Duration placeholder (since not in model, show created date)
                  Text(
                    'Hochgeladen: ${DateFormat('dd.MM.yyyy').format(video.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
                  ),

                  // New tag
                  if (isNew) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'NEU',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}