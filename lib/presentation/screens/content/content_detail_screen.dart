import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:jugendkompass_app/domain/providers/content_provider.dart';
import 'package:jugendkompass_app/domain/providers/favorites_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/full_player_screen.dart';

class ContentDetailScreen extends ConsumerWidget {
  final String contentId;

  const ContentDetailScreen({
    super.key,
    required this.contentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentDetailProvider(contentId));
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      body: contentAsync.when(
        data: (content) {
          if (content == null) {
            return const ErrorView(
              message: 'Inhalt nicht gefunden',
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    content.displayTitle,
                    style: const TextStyle(
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  background: content.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: content.thumbnailUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            content.isAudio
                                ? Icons.headphones
                                : content.isVideo
                                    ? Icons.play_circle
                                    : Icons.article,
                            size: 80,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (content.description != null && content.description!.isNotEmpty) ...[
                      Html(
                        data: content.description!,
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            fontSize: FontSize(Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16),
                            lineHeight: const LineHeight(1.6),
                          ),
                          "p": Style(
                            margin: Margins.only(bottom: 12),
                            fontSize: FontSize(Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16),
                            lineHeight: const LineHeight(1.6),
                          ),
                          "h1": Style(
                            fontSize: FontSize(24),
                            fontWeight: FontWeight.bold,
                            margin: Margins.only(bottom: 8, top: 16),
                          ),
                          "h2": Style(
                            fontSize: FontSize(20),
                            fontWeight: FontWeight.bold,
                            margin: Margins.only(bottom: 8, top: 16),
                          ),
                          "h3": Style(
                            fontSize: FontSize(18),
                            fontWeight: FontWeight.bold,
                            margin: Margins.only(bottom: 8, top: 12),
                          ),
                          "a": Style(
                            color: Theme.of(context).colorScheme.primary,
                            textDecoration: TextDecoration.underline,
                          ),
                          "ul": Style(
                            margin: Margins.only(left: 16, bottom: 12),
                          ),
                          "ol": Style(
                            margin: Margins.only(left: 16, bottom: 12),
                          ),
                          "li": Style(
                            margin: Margins.only(bottom: 4),
                          ),
                          "strong": Style(
                            fontWeight: FontWeight.bold,
                          ),
                          "em": Style(
                            fontStyle: FontStyle.italic,
                          ),
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (content.isAudio && content.audioId != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.headphones,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Audio verfügbar',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () async {
                                  // Fetch audio from repository and play it
                                  try {
                                    final audioRepo = ref.read(audioRepositoryProvider);
                                    final audioList = await audioRepo.getAudioList(limit: 1000);
                                    final audio = audioList.firstWhere(
                                      (a) => a.id == content.audioId,
                                      orElse: () => AudioModel(
                                        id: content.audioId!,
                                        url: '',
                                      ),
                                    );

                                    if (audio.url.isEmpty) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Audio-URL nicht gefunden'),
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    // Set current audio and navigate to player
                                    ref.read(currentAudioProvider.notifier).state = audio;
                                    final audioService = ref.read(audioServiceProvider);
                                    await audioService.playAudio(audio.audioUrl);

                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const FullPlayerScreen(),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Fehler: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Anhören'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (content.isVideo && content.audioId != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.play_circle,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Video Player kommt bald',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Video-Player muss noch integriert werden',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: null, // Disabled until video player is integrated
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Anschauen'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(
          message: 'Lade Inhalt...',
        ),
        error: (error, stack) => ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(contentDetailProvider(contentId));
          },
        ),
      ),
      floatingActionButton: contentAsync.maybeWhen(
        data: (content) {
          if (content == null) return null;
          final isFavorite = favorites.contains(content.id);
          return FloatingActionButton(
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(content.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite
                        ? 'Aus Favoriten entfernt'
                        : 'Zu Favoriten hinzugefügt',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}
