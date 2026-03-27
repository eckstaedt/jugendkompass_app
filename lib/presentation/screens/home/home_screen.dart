import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/verse_provider.dart';
import 'package:jugendkompass_app/domain/providers/profile_provider.dart';
import 'package:jugendkompass_app/domain/providers/impulse_provider.dart';
import 'package:jugendkompass_app/domain/providers/recommendation_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/verse_card.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/impulse_card.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/recommended_content_tile.dart';
import 'package:jugendkompass_app/presentation/screens/impulse/impulse_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/post/post_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart'
    show kVideoPlayerRouteName;
import 'package:jugendkompass_app/presentation/navigation/fade_page_route.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<RecommendedItem> _allContent = [];
  final Set<String> _seenIds = {};
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _initialLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent();
    });
  }

  Future<void> _loadContent() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final items = await ref.read(paginatedContentProvider(_currentPage).future);
      if (mounted) {
        setState(() {
          for (final item in items) {
            if (_seenIds.add(item.id)) {
              _allContent.add(item);
            }
          }
          // Sort chronologically: newest first
          _allContent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _hasMore = items.length >= 50;
          _currentPage++;
          _isLoadingMore = false;
          _initialLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _initialLoaded = true;
        });
      }
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(dailyVerseProvider);
    ref.invalidate(dailyImpulsesProvider);
    final oldPage = _currentPage;
    setState(() {
      _allContent.clear();
      _seenIds.clear();
      _currentPage = 0;
      _hasMore = true;
      _initialLoaded = false;
    });
    for (int i = 0; i <= oldPage; i++) {
      ref.invalidate(paginatedContentProvider(i));
    }
    await _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);

    final translate = ref.watch(stringTranslatorProvider);
    final verseAsync = ref.watch(dailyVerseProvider);
    final impulsesAsync = ref.watch(dailyImpulsesProvider);
    final userName = ref.watch(userNameProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.pixels >
                        scrollInfo.metrics.maxScrollExtent - 300 &&
                    !_isLoadingMore &&
                    _hasMore) {
                  _loadContent();
                }
                return false;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Greeting Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        DesignTokens.paddingHorizontal,
                        24,
                        DesignTokens.paddingHorizontal,
                        DesignTokens.spacingMedium,
                      ),
                      child: Text(
                        'Shalom, ${userName ?? "User"}',
                        style: GoogleFonts.poppins(
                          textStyle: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ) ??
                              const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),

                  // Verse of the Day
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.paddingHorizontal),
                      child: verseAsync.when(
                        data: (verse) {
                          if (verse == null) {
                            return SizedBox(
                              height: 200,
                              child: Center(
                                child: Text('Kein Vers für heute verfügbar'),
                              ),
                            );
                          }
                          return VerseCard(verse: verse);
                        },
                        loading: () => const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stack) => SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 40),
                                const SizedBox(height: 8),
                                Text('${translate('Fehler')}: $error',
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () {
                                    ref.invalidate(dailyVerseProvider);
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: Text(translate('Erneut versuchen')),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // Impulses Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        DesignTokens.paddingHorizontal,
                        DesignTokens.spacingMedium,
                        DesignTokens.paddingHorizontal,
                        DesignTokens.spacingSmall,
                      ),
                      child: Text(
                        translate('Impulse'),
                        style: GoogleFonts.poppins(
                          textStyle: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ) ??
                              const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Impulses List
                  SliverToBoxAdapter(
                    child: impulsesAsync.when(
                      data: (impulses) {
                        if (impulses.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                                child: Text('Keine Impulse verfügbar')),
                          );
                        }
                        return SizedBox(
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignTokens.paddingHorizontal,
                            ),
                            itemCount: impulses.length,
                            itemBuilder: (context, index) {
                              final impulse = impulses[index];
                              return ImpulseCard(
                                impulse: impulse,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    FadePageRoute(
                                      builder: (context) =>
                                          ImpulseDetailScreen(impulse: impulse),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, stack) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                              'Fehler beim Laden: $error'),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // ── Unified "Kürzliche Inhalte" Section ──────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        DesignTokens.paddingHorizontal,
                        DesignTokens.spacingMedium,
                        DesignTokens.paddingHorizontal,
                        DesignTokens.spacingSmall,
                      ),
                      child: Text(
                        translate('Kürzliche Inhalte'),
                        style: GoogleFonts.poppins(
                          textStyle: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ) ??
                              const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Paginated content list
                  if (!_initialLoaded)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_allContent.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                            child: Text(translate('Keine Inhalte verfügbar'))),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.paddingHorizontal,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = _allContent[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: RecommendedContentTile(
                                item: item,
                                isNewest: index == 0,
                                onTap: () => _navigateToContent(context, item),
                              ),
                            );
                          },
                          childCount: _allContent.length,
                        ),
                      ),
                    ),

                  // Loading more indicator
                  if (_isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),

                  // Bottom spacing
                  SliverToBoxAdapter(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final hasAudio = ref.watch(currentAudioProvider) != null;
                        return SizedBox(height: hasAudio ? 180 : 100);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToContent(BuildContext context, RecommendedItem item) {
    if (item.isVideo && item.video != null) {
      Navigator.push(
        context,
        FadePageRoute(
          settings: const RouteSettings(name: kVideoPlayerRouteName),
          builder: (context) => VideoPlayerScreen(
            videoUrl: item.video!.videoUrl,
            title: item.video!.displayTitle,
          ),
        ),
      );
    } else if (item.post != null) {
      Navigator.push(
        context,
        FadePageRoute(
          builder: (context) => PostDetailScreen(post: item.post!),
        ),
      );
    }
  }
}
