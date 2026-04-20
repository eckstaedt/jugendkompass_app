import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:jugendkompass_app/data/models/post_model.dart';
import 'package:jugendkompass_app/data/models/collection_item_model.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart' show currentAudioNotifier;
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/collection_provider.dart';
import 'package:jugendkompass_app/domain/providers/translation_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/utils/html_utils.dart';

import 'package:google_fonts/google_fonts.dart';

class PostDetailScreen extends ConsumerWidget {
  final PostModel post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasAudio = post.audioId != null;
    ref.watch(languageProvider);
    final isInCollection = ref.watch(collectionProvider).any(
          (item) => item.id == post.id && item.type == CollectionItemType.post,
        );

    // Translate post content to the selected app language
    final translationAsync = ref.watch(
      translatePostProvider((
        id: post.id,
        title: post.title,
        body: post.body,
      )),
    );
    final displayTitle = translationAsync.whenOrNull(data: (d) => d.title) ?? post.title;
    final displayBody = translationAsync.whenOrNull(data: (d) => d.body) ?? post.body;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          hasAudio ? 'Podcast' : 'Artikel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final item = CollectionItem(
                    id: post.id,
                    title: HtmlUtils.stripHtml(displayTitle),
                    description: HtmlUtils.stripAndTruncate(displayBody, maxLength: 200),
                    imageUrl: post.imageUrl,
                    type: CollectionItemType.post,
                    author: post.categoryName,
                    savedAt: DateTime.now(),
                  );
                  ref.read(collectionProvider.notifier).toggleCollection(item);
                },
                child: Icon(
                  isInCollection ? Icons.bookmark : Icons.bookmark_outline,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.paddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if available
            if (post.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
                child: CorsNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Title
            Text(
              HtmlUtils.stripHtml(displayTitle),
              style: GoogleFonts.poppins(
                textStyle: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Meta information
            Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      // Category/tag badges
                          if ((post.categoryNames ?? []).isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: post.categoryNames!
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(DesignTokens.radiusBadges),
                                      ),
                                      child: Text(
                                        tag.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            )
                          else if (post.categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(DesignTokens.radiusBadges),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.label,
                                    size: 16,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    post.categoryName!.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                      // Audio badge
                      if (hasAudio)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusBadges),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.headphones,
                                size: 16,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'AUDIO',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Reading time
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _calculateReadingTime(displayBody),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Audio play / pause button
                  if (hasAudio) ...[  
                    const SizedBox(height: 24),
                    Consumer(
                      builder: (context, ref, _) {
                        final current = ref.watch(currentAudioProvider);
                        final isPlaying = ref.watch(isPlayingProvider);
                        final isThisAudio =
                            current != null && current.id == post.audioId;
                        final isThisPlaying = isThisAudio && isPlaying;

                        return SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              if (isThisPlaying) {
                                // Pause via audioService
                                await ref
                                    .read(audioServiceProvider)
                                    .pause();
                              } else if (isThisAudio) {
                                // Resume same audio
                                await ref
                                    .read(audioServiceProvider)
                                    .resume();
                              } else {
                                // Load + play this article's audio
                                await _playAudio(context, ref);
                              }
                            },
                            icon: Icon(
                              isThisPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            label: Text(
                              isThisPlaying
                                  ? 'Pausieren'
                                  : isThisAudio
                                      ? 'Weiter anhören'
                                      : 'Artikel anhören',
                            ),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 32),

                  // HTML Content
                  Html(
                    data: displayBody,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(18),
                        lineHeight: const LineHeight(1.8),
                        color: theme.colorScheme.onSurface,
                      ),
                      "p": Style(
                        margin: Margins.only(bottom: 16),
                        fontSize: FontSize(18),
                        lineHeight: const LineHeight(1.8),
                      ),
                      "h1": Style(
                        fontSize: FontSize(28),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(bottom: 12, top: 24),
                      ),
                      "h2": Style(
                        fontSize: FontSize(24),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(bottom: 10, top: 20),
                      ),
                      "h3": Style(
                        fontSize: FontSize(20),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(bottom: 8, top: 16),
                      ),
                      "a": Style(
                        color: theme.colorScheme.primary,
                        textDecoration: TextDecoration.underline,
                      ),
                      "ul": Style(
                        margin: Margins.only(left: 20, bottom: 16),
                      ),
                      "ol": Style(
                        margin: Margins.only(left: 20, bottom: 16),
                      ),
                      "li": Style(
                        margin: Margins.only(bottom: 8),
                      ),
                      "blockquote": Style(
                        margin: Margins.only(left: 16, top: 16, bottom: 16),
                        padding: HtmlPaddings.only(left: 16),
                        border: Border(
                          left: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 4,
                          ),
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                      "strong": Style(
                        fontWeight: FontWeight.bold,
                      ),
                      "em": Style(
                        fontStyle: FontStyle.italic,
                      ),
                      "img": Style(
                        display: Display.none,
                      ),
                    },
                  ),

            Consumer(
              builder: (context, ref, _) {
                final hasAudio = ref.watch(currentAudioProvider) != null;
                return SizedBox(
                  height: hasAudio
                      ? DesignTokens.overlayPaddingWithMiniPlayer
                      : DesignTokens.overlayPaddingBase,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate reading time from HTML content
  /// Assumes average reading speed of 200 words per minute
  String _calculateReadingTime(String htmlContent) {
    // Remove HTML tags
    final text = htmlContent.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // Count words (split by whitespace and filter empty strings)
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

    // Calculate reading time (200 words per minute)
    final minutes = (words / 200).ceil();

    // Return formatted string
    if (minutes < 1) {
      return '< 1 MIN LESEZEIT';
    } else if (minutes == 1) {
      return '1 MIN LESEZEIT';
    } else {
      return '$minutes MIN LESEZEIT';
    }
  }

  /// Play audio for this post
  Future<void> _playAudio(BuildContext context, WidgetRef ref) async {
    if (post.audioId == null) return;

    try {
      // Fetch the audio
      final audioRepository = ref.read(audioRepositoryProvider);
      final audio = await audioRepository.getAudioById(post.audioId!);

      if (audio == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTranslations.t('audio_not_found')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Enrich audio with the current post's metadata so the mini bar
      // always shows the correct title and thumbnail image.
      final enrichedAudio = audio.copyWith(
        title: audio.title?.isNotEmpty == true ? audio.title : post.title,
        thumbnailUrl: audio.imageUrl?.isNotEmpty == true
            ? audio.imageUrl
            : post.imageUrl,
      );

      // Update providers immediately so the mini player bar appears instantly
      ref.read(audioQueueProvider.notifier).state = [enrichedAudio];
      ref.read(currentQueueIndexProvider.notifier).state = 0;
      ref.read(currentAudioProvider.notifier).state = enrichedAudio;
      currentAudioNotifier.value = enrichedAudio;

      // Start playback (setQueue calls playAudio internally)
      final audioService = ref.read(audioServiceProvider);
      await audioService.setQueue([enrichedAudio], startIndex: 0);
    } catch (e) {
      if (context.mounted) {
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
