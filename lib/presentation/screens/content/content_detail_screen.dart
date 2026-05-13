import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/post_provider.dart';
import 'package:jugendkompass_app/domain/providers/video_provider.dart';
import 'package:jugendkompass_app/domain/providers/content_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart'
    show kVideoPlayerRouteName;
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
    final translate = ref.watch(stringTranslatorProvider);

    return contentAsync.when(
      data: (content) {
        if (content == null) {
          return Scaffold(
            appBar: AppBar(title: Text(translate('Inhalt'))),
            body: ErrorView(
              message: translate('Inhalt nicht gefunden'),
            ),
          );
        }

        if (content.isVideo) {
          final videoAsync = ref.watch(videoByContentIdProvider(contentId));
          return videoAsync.when(
            data: (video) {
              if (video == null) {
                return Scaffold(
                  appBar: AppBar(title: Text(translate('Video'))),
                  body: ErrorView(
                    message: translate('Video nicht gefunden'),
                  ),
                );
              }
              // Push VideoPlayerScreen with proper route settings so the
              // navbar observer can hide the navbar during video playback.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: kVideoPlayerRouteName),
                      builder: (context) => VideoPlayerScreen(
                        videoUrl: video.videoUrl,
                        title: video.displayTitle,
                        description: video.description,
                        imageUrl: video.imageUrl,
                      ),
                    ),
                  );
                }
              });
              return Scaffold(
                appBar: AppBar(title: Text(translate('Video'))),
                body: LoadingIndicator(message: translate('Lade Video...')),
              );
            },
            loading: () => Scaffold(
              appBar: AppBar(title: Text(translate('Laden...'))),
              body: LoadingIndicator(
                message: translate('Lade Video...'),
              ),
            ),
            error: (error, stack) => Scaffold(
              appBar: AppBar(title: Text(translate('Fehler'))),
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
                appBar: AppBar(title: Text(translate('Inhalt'))),
                body: ErrorView(
                  message: translate('Inhalt nicht gefunden'),
                ),
              );
            }
            return PostDetailScreen(post: posts.first);
          },
          loading: () => Scaffold(
            appBar: AppBar(title: Text(translate('Laden...'))),
            body: LoadingIndicator(
              message: translate('Lade Inhalt...'),
            ),
          ),
          error: (error, stack) => Scaffold(
            appBar: AppBar(title: Text(translate('Fehler'))),
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
        appBar: AppBar(title: Text(translate('Laden...'))),
        body: LoadingIndicator(
          message: translate('Lade Inhalt...'),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(translate('Fehler'))),
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
