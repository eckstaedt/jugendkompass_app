import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/verse_provider.dart';
import 'package:jugendkompass_app/domain/providers/profile_provider.dart';
import 'package:jugendkompass_app/domain/providers/impulse_provider.dart';
import 'package:jugendkompass_app/domain/providers/recommendation_provider.dart';
import 'package:jugendkompass_app/domain/providers/post_provider.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/verse_card.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/impulse_card.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/recommended_content_tile.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/section_header.dart';
import 'package:jugendkompass_app/presentation/screens/impulse/impulse_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/impulse/impulse_list_screen.dart';
import 'package:jugendkompass_app/presentation/screens/post/post_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseAsync = ref.watch(dailyVerseProvider);
    final impulsesAsync = ref.watch(dailyImpulsesProvider);
    final recommendationsAsync = ref.watch(recommendedContentProvider);
    final latestPostAsync = ref.watch(latestPostProvider);
    final userName = ref.watch(userNameProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyVerseProvider);
          ref.invalidate(dailyImpulsesProvider);
          ref.invalidate(recommendedContentProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Greeting
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.paddingHorizontal,
                  48,
                  DesignTokens.paddingHorizontal,
                  DesignTokens.spacingMedium,
                ),
                child: Text(
                  'Hi, ${userName ?? "User"}',
                  style: GoogleFonts.poppins(
                    textStyle: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ) ?? const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),

            // Verse of the Day
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.paddingHorizontal),
                child: verseAsync.when(
                  data: (verse) {
                    if (verse == null) {
                      return const SizedBox(
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
                          Text('Fehler: $error', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () {
                              ref.invalidate(dailyVerseProvider);
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Erneut versuchen'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Spacing
            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Impulses Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.paddingHorizontal),
                child: SectionHeader(
                  title: 'Impulse',
                  actionText: 'Alle anzeigen',
                  onActionTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ImpulseListScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Impulses List
            SliverToBoxAdapter(
              child: impulsesAsync.when(
                data: (impulses) {
                  if (impulses.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Keine Impulse verfügbar')),
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
                              MaterialPageRoute(
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
                    child: Text('Fehler beim Laden der Impulse: $error'),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Recommendations Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.paddingHorizontal),
                child: SectionHeader(
                  title: '✨ Für Dich empfohlen',
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Recommendations List
            SliverToBoxAdapter(
              child: recommendationsAsync.when(
                data: (recommendations) {
                  if (recommendations.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Keine Empfehlungen verfügbar')),
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.paddingHorizontal,
                    ),
                    child: Column(
                      children: List.generate(
                        recommendations.length,
                        (index) {
                          final item = recommendations[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RecommendedContentTile(
                              item: item,
                              onTap: () => _navigateToContent(
                                context,
                                item,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Fehler beim Laden der Empfehlungen: $error'),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Latest Post Section
            SliverToBoxAdapter(
              child: latestPostAsync.when(
                data: (post) {
                  if (post == null) return const SizedBox.shrink();
                  final item = RecommendedItem.fromPost(post);
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.paddingHorizontal,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Neuester Beitrag',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RecommendedContentTile(
                          item: item,
                          onTap: () => _navigateToContent(context, item),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  void _navigateToContent(BuildContext context, RecommendedItem item) {
    if (item.isVideo && item.video != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoUrl: item.video!.videoUrl,
            title: item.video!.displayTitle,
          ),
        ),
      );
    } else if (item.post != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(post: item.post!),
        ),
      );
    }
  }
}
