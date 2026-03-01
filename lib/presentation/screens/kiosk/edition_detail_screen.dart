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
import 'package:jugendkompass_app/core/config/design_tokens.dart';

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
          Positioned.fill(
            child: edition.coverImageUrl != null
                ? CorsNetworkImage(imageUrl: edition.coverImageUrl!, fit: BoxFit.cover)
                : const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF2B6CB0), Color(0xFF6B46C1)]),
                    ),
                  ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ),
          ),

          if (edition.pdfUrl != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.white), onPressed: () => _openPDF(context, edition.pdfUrl!)),
              ),
            ),

          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.6,
            maxChildSize: 0.94,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(color: DesignTokens.appBackground, borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLargeCards))),
                child: Column(
                  children: [
                    Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
                    Expanded(
                      child: audiosAsync.when(
                        data: (audios) => postsAsync.when(
                          data: (posts) => _buildContent(context, ref, scrollController, posts, audios),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, s) => Center(child: Text('Fehler: $e')),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => postsAsync.when(
                          data: (posts) => _buildContent(context, ref, scrollController, posts, []),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, s) => Center(child: Text('Fehler: $e')),
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

  Widget _buildContent(BuildContext context, WidgetRef ref, ScrollController scrollController, List<PostModel> posts, List<AudioModel> audios) {
    final theme = Theme.of(context);
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(DesignTokens.paddingHorizontal, 0, DesignTokens.paddingHorizontal, 24),
      children: [
        Text(edition.name.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontSize: 12, letterSpacing: 1.5, color: DesignTokens.primaryRed, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(edition.displayTitle, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: DesignTokens.textPrimary)),
        const SizedBox(height: 20),
        // Audio controls: first allow playing the foreword (if present), then the full edition
        if (audios.isNotEmpty) ...[
          if (audios.length > 1) // assume first track is "Vorwort"
            FilledButton.icon(
              onPressed: () => _playVorwort(context, ref, audios),
              icon: const Icon(Icons.headphones, size: 24),
              label: const Text('Vorwort anhören', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.primaryRed.withOpacity(0.85),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButtons)),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _playEditionAudios(context, ref, audios),
            icon: const Icon(Icons.play_arrow, size: 24),
            label: const Text('Ausgabe anhören', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.primaryRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButtons)),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (edition.description != null && edition.description!.isNotEmpty) ...[
          Html(data: edition.description!, style: {
            "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero, fontSize: FontSize(16), color: DesignTokens.textSecondary),
            "p": Style(margin: Margins.only(bottom: 12), fontSize: FontSize(16), lineHeight: const LineHeight(1.6), color: DesignTokens.textSecondary),
            "h1": Style(fontSize: FontSize(24), fontWeight: FontWeight.bold, color: DesignTokens.textPrimary, margin: Margins.only(bottom: 8, top: 16)),
            "h2": Style(fontSize: FontSize(20), fontWeight: FontWeight.bold, color: DesignTokens.textPrimary, margin: Margins.only(bottom: 8, top: 16)),
            "h3": Style(fontSize: FontSize(18), fontWeight: FontWeight.bold, color: DesignTokens.textPrimary, margin: Margins.only(bottom: 8, top: 12)),
            "a": Style(color: DesignTokens.primaryRed, textDecoration: TextDecoration.underline),
            "ul": Style(margin: Margins.only(left: 16, bottom: 12)),
            "ol": Style(margin: Margins.only(left: 16, bottom: 12)),
            "li": Style(margin: Margins.only(bottom: 4)),
            "strong": Style(fontWeight: FontWeight.bold),
            "em": Style(fontStyle: FontStyle.italic),
          }),
          const SizedBox(height: 32),
        ],
        Row(children: [const Icon(Icons.article, size: 20, color: Colors.black), const SizedBox(width: 8), Text('Artikel in dieser Ausgabe', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: DesignTokens.textPrimary))]),
        const SizedBox(height: 16),
        if (posts.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Center(child: Text('Keine Artikel verfügbar', style: TextStyle(color: Colors.grey.shade600))))
        else
          ...List.generate(posts.length, (index) => _buildPostCard(context, ref, posts[index], index + 1)),
      ],
    );
  }

  Widget _buildPostCard(BuildContext context, WidgetRef ref, PostModel post, int index) {
    final hasAudio = post.audioId != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: DesignTokens.cardBackground, borderRadius: BorderRadius.circular(DesignTokens.radiusButtons), boxShadow: [DesignTokens.shadowSubtle]),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(DesignTokens.radiusInputFields), child: post.imageUrl != null ? CorsNetworkImage(imageUrl: post.imageUrl!, width: 60, height: 60, fit: BoxFit.cover, placeholder: Container(width: 60, height: 60, color: DesignTokens.cardBackground, child: Center(child: Text('$index', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DesignTokens.primaryRed)))), errorWidget: Container(width: 60, height: 60, color: DesignTokens.cardBackground, child: Center(child: Text('$index', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DesignTokens.primaryRed))))) : Container(width: 60, height: 60, decoration: BoxDecoration(color: DesignTokens.cardBackground, borderRadius: BorderRadius.circular(12)), child: Center(child: Text('$index', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DesignTokens.primaryRed))))),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DesignTokens.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // show one or more category/tag badges
                  if ((post.categoryNames ?? []).isNotEmpty)
                    ...post.categoryNames!.map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: DesignTokens.redBackground,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DesignTokens.primaryRed),
                            ),
                          ),
                        ))
                  else if (post.categoryName != null)
                    Text(
                      post.categoryName!.toUpperCase(),
                      style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  const Text(' • '),
                  Text(
                    _calculateReadingTime(post.body),
                    style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary),
                  )
                ],
              )
            ],
          ),
        ),
        if (hasAudio)
          IconButton(onPressed: () => _playPostAudio(context, ref, post), icon: Icon(Icons.play_circle, size: 40, color: DesignTokens.primaryRed))
      ]),
    );
  }

  Future<void> _playEditionAudios(BuildContext context, WidgetRef ref, List<AudioModel> audios) async {
    if (audios.isEmpty) return;
    try {
      final audioService = ref.read(audioServiceProvider);
      await audioService.setQueue(audios, startIndex: 0);
      ref.read(audioQueueProvider.notifier).state = audios;
      ref.read(currentQueueIndexProvider.notifier).state = 0;
      ref.read(currentAudioProvider.notifier).state = audios.first;
      if (context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FullPlayerScreen()));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Abspielen: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _playPostAudio(BuildContext context, WidgetRef ref, PostModel post) async {
    if (post.audioId == null) return;
    try {
      final audioRepository = ref.read(audioRepositoryProvider);
      final audio = await audioRepository.getAudioById(post.audioId!);
      if (audio == null) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio nicht gefunden'), backgroundColor: Colors.red));
        return;
      }
      final audioService = ref.read(audioServiceProvider);
      ref.read(currentAudioProvider.notifier).state = audio;
      await audioService.playAudio(audio.url);
      if (context.mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FullPlayerScreen()));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Abspielen: $e'), backgroundColor: Colors.red));
    }
  }

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Öffnen des PDFs: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Play only the first audio from the edition, used for a possible "Vorwort" track.
  Future<void> _playVorwort(BuildContext context, WidgetRef ref, List<AudioModel> audios) async {
    if (audios.isEmpty) return;
    // simply delegate to _playEditionAudios with a single-item list
    await _playEditionAudios(context, ref, [audios.first]);
  }

  String _calculateReadingTime(String htmlContent) {
    final text = htmlContent.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    final minutes = (words / 200).ceil();
    if (minutes < 1) return '< 1 MIN';
    if (minutes == 1) return '1 MIN';
    return '$minutes MIN';
  }
}
// trailing duplicate code removed – file ends correctly above
