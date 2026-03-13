import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/video_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

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

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75, // Adjust for thumbnail and title
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemCount: filteredVideos.length,
                    itemBuilder: (context, index) {
                      final video = filteredVideos[index];
                      final isNew = video.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)));

                      return VideoCard(
                        video: video,
                        isNew: isNew,
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
        padding: const EdgeInsets.all(8),
        withShadow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Thumbnail
            Expanded(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                  child: SizedBox(
                    width: double.infinity,
                    child: video.imageUrl != null
                        ? CorsNetworkImage(
                            imageUrl: video.imageUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: DesignTokens.glassBackground(0.2),
                            child: const Icon(Icons.video_library, size: 48),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Video Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  video.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // New tag
                if (isNew) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
          ],
        ),
      ),
    );
  }
}