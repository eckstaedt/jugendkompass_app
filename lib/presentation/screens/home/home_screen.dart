import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/verse_provider.dart';
import 'package:jugendkompass_app/domain/providers/profile_provider.dart';
import 'package:jugendkompass_app/domain/providers/impulse_provider.dart';
import 'package:jugendkompass_app/domain/providers/recommendation_provider.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/verse_card.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/impulse_card.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/recommended_content_tile.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/section_header.dart';
import 'package:jugendkompass_app/presentation/screens/impulse/impulse_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/impulse/impulse_list_screen.dart';
import 'package:jugendkompass_app/presentation/screens/post/post_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseAsync = ref.watch(dailyVerseProvider);
    final impulsesAsync = ref.watch(dailyImpulsesProvider);
    final recommendationsAsync = ref.watch(recommendedContentProvider);
    final userName = ref.watch(userNameProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            // Custom Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.paddingHorizontal,
                  48,
                  DesignTokens.paddingHorizontal,
                  DesignTokens.spacingMedium,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryRed,
                  boxShadow: [DesignTokens.shadowSubtle],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WILLKOMMEN ZURÜCK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hi ${userName ?? "User"}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Verse of the Day Section
            SliverToBoxAdapter(
              child: verseAsync.when(
                data: (verse) {
                  if (verse == null) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('Kein Vers für heute verfügbar'),
                      ),
                    );
                  }
                  return VerseCard(verse: verse);
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 8),
                        Text('Fehler beim Laden: $error'),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            ref.invalidate(dailyVerseProvider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Impulses Section
            SliverToBoxAdapter(
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

            // Impulses horizontal scroll
            SliverToBoxAdapter(
              child: impulsesAsync.when(
                data: (impulses) {
                  if (impulses.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('Keine Impulse verfügbar'),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: impulses.length,
                      itemBuilder: (context, index) {
                        final impulse = impulses[index];
                        return ImpulseCard(
                          impulse: impulse,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImpulseDetailScreen(impulse: impulse),
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
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text('Fehler beim Laden der Impulse: $error'),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Recommended Content Section
            SliverToBoxAdapter(
              child: SectionHeader(
                title: '✨ Für Dich empfohlen',
              ),
            ),

            // Recommended content list
            SliverToBoxAdapter(
              child: recommendationsAsync.when(
                data: (recommendations) {
                  if (recommendations.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('Keine Empfehlungen verfügbar'),
                      ),
                    );
                  }
                  return Column(
                    children: recommendations.map((item) {
                      return RecommendedContentTile(
                        item: item,
                        onTap: () {
                          // Navigate to appropriate screen based on content type
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
                                builder: (context) => PostDetailScreen(
                                  post: item.post!,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text('Fehler beim Laden der Empfehlungen: $error'),
                  ),
                ),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }
}
