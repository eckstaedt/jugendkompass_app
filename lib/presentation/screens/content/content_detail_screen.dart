import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/post_provider.dart';
import 'package:jugendkompass_app/domain/providers/video_provider.dart';
import 'package:jugendkompass_app/domain/providers/content_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/screens/post/post_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';

class ContentDetailScreen extends ConsumerWidget {
  final String contentId;

  const ContentDetailScreen({
    super.key,
    required this.contentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentDetailProvider(contentId));

    return contentAsync.when(
      data: (content) {
        if (content == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Inhalt')),
            body: const ErrorView(
              message: 'Inhalt nicht gefunden',
            ),
          );
        }

        if (content.isVideo) {
          final videoAsync = ref.watch(videoByContentIdProvider(contentId));
          return videoAsync.when(
            data: (video) {
              if (video == null) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Video')),
                  body: const ErrorView(
                    message: 'Video nicht gefunden',
                  ),
                );
              }
              return VideoPlayerScreen(
                videoUrl: video.videoUrl,
                title: video.displayTitle,
              );
            },
            loading: () => Scaffold(
              appBar: AppBar(title: const Text('Laden...')),
              body: const LoadingIndicator(
                message: 'Lade Video...',
              ),
            ),
            error: (error, stack) => Scaffold(
              appBar: AppBar(title: const Text('Fehler')),
              body: ErrorView(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(videoByContentIdProvider(contentId));
                },
              ),
            ),
          );
        }

        final postsAsync = ref.watch(postsListProvider(
          PostFilter(contentId: contentId, limit: 1),
        ));

        return postsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Inhalt')),
                body: const ErrorView(
                  message: 'Inhalt nicht gefunden',
                ),
              );
            }
            return PostDetailScreen(post: posts.first);
          },
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('Laden...')),
            body: const LoadingIndicator(
              message: 'Lade Inhalt...',
            ),
          ),
          error: (error, stack) => Scaffold(
            appBar: AppBar(title: const Text('Fehler')),
            body: ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(postsListProvider(
                  PostFilter(contentId: contentId, limit: 1),
                ));
              },
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Laden...')),
        body: const LoadingIndicator(
          message: 'Lade Inhalt...',
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Fehler')),
        body: ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(contentDetailProvider(contentId));
          },
        ),
      ),
    );
  }
}
