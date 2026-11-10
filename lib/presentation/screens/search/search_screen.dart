import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/utils/html_utils.dart';
import 'package:jugendkompass_app/core/utils/search_utils.dart';
import 'package:jugendkompass_app/core/utils/snackbar_utils.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/category_provider.dart';
import 'package:jugendkompass_app/domain/providers/edition_provider.dart';
import 'package:jugendkompass_app/domain/providers/impulse_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/message_provider.dart';
import 'package:jugendkompass_app/domain/providers/post_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/domain/providers/verse_provider.dart';
import 'package:jugendkompass_app/domain/providers/video_provider.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart'
    show currentAudioNotifier, kVideoPlayerRouteName;
import 'package:jugendkompass_app/presentation/screens/impulse/impulse_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/edition_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/presentation/screens/message/message_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/post/post_detail_screen.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';

enum _Type { article, audio, video, impulse, message, edition, verse }

enum _Sort { relevance, newest, oldest }

/// One searchable piece of content, prepared once.
class _Entry {
  _Entry({
    required this.type,
    required this.title,
    required this.date,
    required this.data,
    required this.text,
    this.imageUrl,
  });

  final _Type type;
  final String title;
  final DateTime date;
  final dynamic data;
  final SearchText text;
  final String? imageUrl;
}

class _Hit {
  _Hit(this.entry, this.match);
  final _Entry entry;
  final SearchMatch match;
}

/// Bible verses up to today (the table also holds verses planned ahead).
final _searchVersesProvider = FutureProvider<List<VerseModel>>((ref) {
  final language = ref.watch(languageProvider).locale.languageCode;
  return ref.watch(verseRepositoryProvider).getVerseArchive(language, limit: 2000);
});

/// Everything the search can find, normalised once per data change (not per
/// keystroke). Null while loading.
final _searchIndexProvider = Provider<List<_Entry>?>((ref) {
  final posts = ref.watch(postsListProvider(PostFilter(limit: 2000)));
  final videos = ref.watch(videosListProvider);
  final impulses = ref.watch(dailyImpulsesProvider);
  final messages = ref.watch(messagesListProvider);
  final editions = ref.watch(editionsListProvider);
  final verses = ref.watch(_searchVersesProvider);
  final categories = ref.watch(categoriesProvider);

  final sources = [posts, videos, impulses, messages, editions];
  if (sources.any((s) => s.isLoading && !s.hasValue)) return null;

  final entries = <_Entry>[];
  final categoryNames = {
    for (final c in categories.valueOrNull ?? const []) c.id: c.name,
  };
  final editionTitles = {
    for (final e in editions.valueOrNull ?? const []) e.id: e.displayTitle,
  };

  for (final post in posts.valueOrNull ?? const []) {
    final title = HtmlUtils.stripHtml(post.title);
    entries.add(_Entry(
      type: post.audioId != null ? _Type.audio : _Type.article,
      title: title,
      date: post.createdAt,
      data: post,
      imageUrl: post.imageUrl,
      text: SearchText(
        title: title,
        body: HtmlUtils.stripHtml(post.body),
        extra: [
          ...?post.categoryNames,
          if (post.categoryNames == null && post.categoryName != null) post.categoryName!,
          if (post.categoryId != null) categoryNames[post.categoryId] ?? '',
          if (post.editionId != null) editionTitles[post.editionId] ?? '',
        ].join(' '),
      ),
    ));
  }
  for (final video in videos.valueOrNull ?? const []) {
    final title = HtmlUtils.stripHtml(video.displayTitle);
    entries.add(_Entry(
      type: _Type.video,
      title: title,
      date: video.createdAt,
      data: video,
      imageUrl: video.thumbnailUrl,
      text: SearchText(title: title, body: HtmlUtils.stripHtml(video.description ?? '')),
    ));
  }
  for (final impulse in impulses.valueOrNull ?? const []) {
    final title = HtmlUtils.stripHtml(impulse.displayTitle);
    entries.add(_Entry(
      type: _Type.impulse,
      title: title,
      date: impulse.date,
      data: impulse,
      imageUrl: impulse.imageUrl,
      text: SearchText(title: title, body: HtmlUtils.stripHtml(impulse.impulseText)),
    ));
  }
  for (final message in messages.valueOrNull ?? const []) {
    final title = HtmlUtils.stripHtml(message.displayTitle);
    entries.add(_Entry(
      type: _Type.message,
      title: title,
      date: message.createdAt,
      data: message,
      imageUrl: message.imageUrl,
      text: SearchText(title: title, body: HtmlUtils.stripHtml(message.message)),
    ));
  }
  for (final edition in editions.valueOrNull ?? const []) {
    final title = HtmlUtils.stripHtml(edition.displayTitle);
    entries.add(_Entry(
      type: _Type.edition,
      title: title,
      date: edition.publishedDate,
      data: edition,
      imageUrl: edition.coverImageUrl,
      text: SearchText(
        title: title,
        body: HtmlUtils.stripHtml(edition.description ?? ''),
        extra: edition.name,
      ),
    ));
  }
  for (final verse in verses.valueOrNull ?? const <VerseModel>[]) {
    final reference = HtmlUtils.stripHtml(verse.reference);
    entries.add(_Entry(
      type: _Type.verse,
      title: reference,
      date: verse.date,
      data: verse,
      // Verse texts may contain HTML entities such as &nbsp;.
      text: SearchText(title: reference, body: HtmlUtils.stripHtml(verse.verse)),
    ));
  }
  return entries;
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  SearchQuery _query = SearchQuery.parse('');
  _Type? _filter; // null = all
  _Sort _sort = _Sort.relevance;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _query = SearchQuery.parse(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final translate = ref.watch(stringTranslatorProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Back button + search field (focused right away).
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, DesignTokens.paddingHorizontal, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AppSearchBar(
                      hint: context.tr('search_hint'),
                      controller: _searchController,
                      autofocus: true,
                      showClear: _searchController.text.isNotEmpty,
                      onChanged: (value) {
                        _onChanged(value);
                        setState(() {}); // update clear button
                      },
                      onClear: () {
                        _searchController.clear();
                        setState(() => _query = SearchQuery.parse(''));
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Type filter chips + sort.
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.paddingHorizontal),
                      children: [
                        _chip(translate('Alle'), null),
                        _chip(translate('Artikel'), _Type.article),
                        _chip(translate('Audio'), _Type.audio),
                        _chip(translate('Video'), _Type.video),
                        _chip(translate('Impuls'), _Type.impulse),
                        _chip(translate('Kurznachricht'), _Type.message),
                        _chip(translate('Ausgabe'), _Type.edition),
                        _chip(context.tr('search_filter_verses'), _Type.verse),
                      ],
                    ),
                  ),
                  PopupMenuButton<_Sort>(
                    tooltip: context.tr('search_sort_relevance'),
                    icon: Icon(Icons.sort_rounded, color: DesignTokens.getTextPrimary(brightness)),
                    initialValue: _sort,
                    onSelected: (s) => setState(() => _sort = s),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: _Sort.relevance, child: Text(context.tr('search_sort_relevance'))),
                      PopupMenuItem(value: _Sort.newest, child: Text(translate('Neueste zuerst'))),
                      PopupMenuItem(value: _Sort.oldest, child: Text(translate('Älteste zuerst'))),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, _Type? type) {
    final brightness = Theme.of(context).brightness;
    final selected = _filter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filter = type),
        backgroundColor: DesignTokens.getCardBackground(brightness),
        selectedColor: DesignTokens.primaryRed,
        labelStyle: TextStyle(
          color: selected ? Colors.white : DesignTokens.getTextSecondary(brightness),
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
        side: BorderSide(
          color: selected
              ? DesignTokens.primaryRed
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButtons)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildResults() {
    final index = ref.watch(_searchIndexProvider);
    if (index == null) {
      return LoadingIndicator(message: AppTranslations.t('loading_content'));
    }

    final hits = <_Hit>[];
    for (final entry in index) {
      if (_filter != null && entry.type != _filter) continue;
      final match = SearchMatcher.match(_query, entry.text);
      if (match != null) hits.add(_Hit(entry, match));
    }

    final byRelevance = _sort == _Sort.relevance && !_query.isEmpty;
    hits.sort((a, b) {
      if (byRelevance) {
        final c = b.match.score.compareTo(a.match.score);
        if (c != 0) return c;
      }
      return _sort == _Sort.oldest
          ? a.entry.date.compareTo(b.entry.date)
          : b.entry.date.compareTo(a.entry.date);
    });

    if (hits.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: AppTranslations.t('no_content_found'),
        message: context.tr('search_tip'),
      );
    }

    final brightness = Theme.of(context).brightness;
    return Consumer(
      builder: (context, ref, _) {
        final hasAudio = ref.watch(currentAudioProvider) != null;
        return ListView.separated(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            DesignTokens.paddingHorizontal,
            4,
            DesignTokens.paddingHorizontal,
            hasAudio ? DesignTokens.overlayPaddingWithMiniPlayer : DesignTokens.overlayPaddingBase,
          ),
          itemCount: hits.length + 1,
          separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 8 : 12),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Text(
                context.tr('search_results', {'count': '${hits.length}'}),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DesignTokens.getTextSecondary(brightness),
                ),
              );
            }
            return _ResultTile(
              hit: hits[i - 1],
              query: _query,
              typeLabel: _typeLabel(hits[i - 1].entry.type),
              onTap: () => _open(hits[i - 1].entry),
            );
          },
        );
      },
    );
  }

  String _typeLabel(_Type type) {
    switch (type) {
      case _Type.article:
        return context.tr('article_badge');
      case _Type.audio:
        return context.tr('audio_badge');
      case _Type.video:
        return context.tr('video_badge');
      case _Type.impulse:
        return context.tr('impulse_badge');
      case _Type.message:
        return context.tr('short_message_badge');
      case _Type.edition:
        return context.tr('edition_badge');
      case _Type.verse:
        return context.tr('verse_badge');
    }
  }

  Future<void> _open(_Entry entry) async {
    final data = entry.data;
    switch (entry.type) {
      case _Type.video:
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: kVideoPlayerRouteName),
            builder: (context) => VideoPlayerScreen(
              videoUrl: data.videoUrl,
              title: data.displayTitle,
              description: data.description,
              imageUrl: data.imageUrl,
              shareContentId: data.contentId.isNotEmpty ? data.contentId : data.id,
            ),
          ),
        );
      case _Type.impulse:
        Navigator.push(context, MaterialPageRoute(builder: (_) => ImpulseDetailScreen(impulse: data)));
      case _Type.message:
        Navigator.push(context, MaterialPageRoute(builder: (_) => MessageDetailScreen(message: data)));
      case _Type.edition:
        Navigator.push(context, MaterialPageRoute(builder: (_) => EditionDetailScreen(edition: data)));
      case _Type.verse:
        _showVerse(data as VerseModel);
      case _Type.audio:
        await _playAudio(data);
      case _Type.article:
        Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: data)));
    }
  }

  void _showVerse(VerseModel verse) {
    final brightness = Theme.of(context).brightness;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.getCardBackground(brightness),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLarge)),
      ),
      // The persistent navbar floats above every route, so leave room for it.
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, DesignTokens.overlayPaddingBase),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd.MM.yyyy').format(verse.date),
                style: TextStyle(fontSize: 12, color: DesignTokens.getTextSecondary(brightness)),
              ),
              const SizedBox(height: 12),
              Text(
                HtmlUtils.stripHtml(verse.verse),
                style: GoogleFonts.merriweather(
                  fontSize: 19,
                  height: 1.5,
                  color: DesignTokens.getTextPrimary(brightness),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '— ${HtmlUtils.stripHtml(verse.reference)}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.getTextSecondary(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playAudio(dynamic post) async {
    if (post.audioId == null) return;
    try {
      final audioRepository = ref.read(audioRepositoryProvider);
      final audio = await audioRepository.getAudioById(post.audioId!);
      if (audio == null) {
        if (mounted) SnackBarUtils.showError(context, AppTranslations.t('audio_not_found'));
        return;
      }
      // Update providers immediately so the mini player bar appears instantly
      ref.read(audioQueueProvider.notifier).state = [audio];
      ref.read(currentQueueIndexProvider.notifier).state = 0;
      ref.read(currentAudioProvider.notifier).state = audio;
      currentAudioNotifier.value = audio;
      await ref.read(audioServiceProvider).setQueue([audio], startIndex: 0);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, '${AppTranslations.t('error_playing')}: $e');
    }
  }
}

/// Result row: thumbnail, highlighted title, type + date, text excerpt.
class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.hit,
    required this.query,
    required this.typeLabel,
    required this.onTap,
  });

  final _Hit hit;
  final SearchQuery query;
  final String typeLabel;
  final VoidCallback onTap;

  static IconData _icon(_Type type) {
    switch (type) {
      case _Type.audio:
        return Icons.headphones_rounded;
      case _Type.video:
        return Icons.play_circle_outline_rounded;
      case _Type.impulse:
        return Icons.lightbulb_outline_rounded;
      case _Type.message:
        return Icons.chat_bubble_outline_rounded;
      case _Type.edition:
        return Icons.menu_book_outlined;
      case _Type.verse:
        return Icons.format_quote_rounded;
      case _Type.article:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textPrimary = DesignTokens.getTextPrimary(brightness);
    final textSecondary = DesignTokens.getTextSecondary(brightness);
    final accent = brightness == Brightness.dark ? DesignTokens.primaryRedOnDark : DesignTokens.primaryRed;
    final entry = hit.entry;
    final snippet = entry.type == _Type.verse ? entry.text.rawBody : hit.match.snippet;

    return RoundedCard(
      padding: const EdgeInsets.all(12),
      withShadow: false,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            child: SizedBox(
              width: 60,
              height: 60,
              child: entry.imageUrl != null && entry.imageUrl!.isNotEmpty
                  ? CorsNetworkImage(imageUrl: entry.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                  : ColoredBox(
                      color: DesignTokens.getChipBackground(brightness),
                      child: Icon(_icon(entry.type), color: textSecondary, size: 26),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  _highlighted(entry.title, TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: textPrimary,
                  ), TextStyle(color: accent)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (snippet != null && snippet.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text.rich(
                    _highlighted(snippet, TextStyle(fontSize: 13, height: 1.4, color: textSecondary),
                        TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    BadgeWidget(label: typeLabel),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd.MM.yyyy').format(entry.date),
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _highlighted(String text, TextStyle base, TextStyle hitStyle) {
    return TextSpan(
      style: base,
      children: [
        for (final (part, isHit) in SearchMatcher.highlight(text, query))
          TextSpan(text: part, style: isHit ? hitStyle : null),
      ],
    );
  }
}
