import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jugendkompass_app/data/models/edition_model.dart';
import 'package:jugendkompass_app/data/models/post_model.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/domain/providers/edition_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/full_player_screen.dart';
import 'package:jugendkompass_app/core/config/app_theme.dart';

class EditionDetailScreen extends ConsumerWidget {
  final EditionModel edition;

  const EditionDetailScreen({
    super.key,
    required this.edition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(editionPostsProvider(edition.id));
    final audiosAsync = ref.watch(editionAudiosProvider(edition.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient with cover image
          Positioned.fill(
            child: edition.coverImageUrl != null
                ? CorsNetworkImage(
                    imageUrl: edition.coverImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade600,
                            Colors.purple.shade800,
                          ],
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade600,
                            Colors.purple.shade800,
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade600,
                          Colors.purple.shade800,
                        ],
                      ),
                    ),
                  ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // PDF Download button (top right)
          if (edition.pdfUrl != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  onPressed: () => _openPDF(context, edition.pdfUrl!),
                ),
              ),
            ),

          // Bottom sheet content
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundBeige,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Content
                    Expanded(
                      child: audiosAsync.when(
                        data: (audios) => postsAsync.when(
                          data: (posts) => _buildContent(
                            context,
                            ref,
                            scrollController,
                            posts,
                            audios,
                          ),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (error, stack) => Center(
                            child: Text('Fehler: $error'),
                          ),
                        ),
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) => postsAsync.when(
                          data: (posts) => _buildContent(
                            context,
                            ref,
                            scrollController,
                            posts,
                            [],
                          ),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (error, stack) => Center(
                            child: Text('Fehler: $error'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ScrollController scrollController,
    List<PostModel> posts,
    List<AudioModel> audios,
  ) {
    final theme = Theme.of(context);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        // Edition name as label
        Text(
          edition.name.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        // Edition display title
        Text(
          edition.displayTitle,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 20),

        // "Anhören" button (plays all audios from this edition)
        if (audios.isNotEmpty)
          FilledButton.icon(
            onPressed: () => _playEditionAudios(context, ref, audios),
            icon: const Icon(Icons.play_arrow, size: 24),
            label: Text(
              'Anhören (${audios.length} ${audios.length == 1 ? "Audio" : "Audios"})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Description (HTML content)
        if (edition.description != null && edition.description!.isNotEmpty) ...[
          Html(
            data: edition.description!,
            style: {
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(16),
                lineHeight: const LineHeight(1.6),
                color: AppTheme.textGray,
              ),
              "p": Style(
                margin: Margins.only(bottom: 12),
                fontSize: FontSize(16),
                lineHeight: const LineHeight(1.6),
                color: AppTheme.textGray,
              ),
              "h1": Style(
                fontSize: FontSize(24),
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                margin: Margins.only(bottom: 8, top: 16),
              ),
              "h2": Style(
                fontSize: FontSize(20),
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                margin: Margins.only(bottom: 8, top: 16),
              ),
              "h3": Style(
                fontSize: FontSize(18),
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                margin: Margins.only(bottom: 8, top: 12),
              ),
              "a": Style(
                color: AppTheme.primaryColor,
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
          const SizedBox(height: 32),
        ],

        // "Artikel in dieser Ausgabe" header
        Row(
          children: [
            const Icon(
              Icons.article,
              size: 20,
              color: AppTheme.textDark,
            ),
            const SizedBox(width: 8),
            Text(
              'Artikel in dieser Ausgabe',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Posts list
        if (posts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Keine Artikel verfügbar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          )
        else
          ...List.generate(posts.length, (index) {
            return _buildPostCard(
              context,
              ref,
              posts[index],
              index + 1,
            );
          }),
      ],
    );
  }

  Widget _buildPostCard(
    BuildContext context,
    WidgetRef ref,
    PostModel post,
    int index,
  ) {
    final hasAudio = post.audioId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Post image or numbered badge
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: post.imageUrl != null
                ? CorsNetworkImage(
                    imageUrl: post.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.backgroundBeige,
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.backgroundBeige,
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundBeige,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      (post.categoryName ?? 'ALLGEMEIN').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    Text(
                      _calculateReadingTime(post.body),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Play button (if has audio)
          if (hasAudio)
            IconButton(
              onPressed: () => _playPostAudio(context, ref, post),
              icon: const Icon(
                Icons.play_circle,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  /// Play all audios from this edition
  Future<void> _playEditionAudios(
    BuildContext context,
    WidgetRef ref,
    List<AudioModel> audios,
  ) async {
    if (audios.isEmpty) return;

    try {
      // Play the first audio
      final firstAudio = audios.first;
      final audioService = ref.read(audioServiceProvider);

      // Set current audio
      ref.read(currentAudioProvider.notifier).state = firstAudio;

      // Play the audio
      await audioService.playAudio(firstAudio.url);

      // Navigate to full player
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const FullPlayerScreen(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Abspielen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Play audio for a specific post
  Future<void> _playPostAudio(
    BuildContext context,
    WidgetRef ref,
    PostModel post,
  ) async {
    if (post.audioId == null) return;

    try {
      // Fetch the audio
      final audioRepository = ref.read(audioRepositoryProvider);
      final audio = await audioRepository.getAudioById(post.audioId!);

      if (audio == null) {
        throw Exception('Audio nicht gefunden');
      }

      final audioService = ref.read(audioServiceProvider);

      // Set current audio
      ref.read(currentAudioProvider.notifier).state = audio;

      // Play the audio
      await audioService.playAudio(audio.url);

      // Navigate to full player
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const FullPlayerScreen(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Abspielen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Open PDF in external viewer or browser
  Future<void> _openPDF(BuildContext context, String pdfUrl) async {
    try {
      final uri = Uri.parse(pdfUrl);
      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('PDF konnte nicht geöffnet werden');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Öffnen des PDFs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      return '< 1 MIN';
    } else if (minutes == 1) {
      return '1 MIN';
    } else {
      return '$minutes MIN';
    }
  }
}
