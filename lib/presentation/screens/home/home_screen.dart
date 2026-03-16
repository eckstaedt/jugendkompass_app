import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jugendkompass_app/domain/providers/verse_provider.dart';
import 'package:jugendkompass_app/domain/providers/profile_provider.dart';
import 'package:jugendkompass_app/domain/providers/impulse_provider.dart';
import 'package:jugendkompass_app/domain/providers/recommendation_provider.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/verse_card.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/impulse_card.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/recommended_content_tile.dart';
import 'package:jugendkompass_app/presentation/screens/impulse/impulse_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/post/post_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/presentation/screens/profile/profile_edit_screen.dart';
import 'package:jugendkompass_app/presentation/navigation/fade_page_route.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseAsync = ref.watch(dailyVerseProvider);
    final impulsesAsync = ref.watch(dailyImpulsesProvider);
    final latestContentAsync = ref.watch(latestContentProvider);
    final recentContentAsync = ref.watch(recentContentProvider);
    final userName = ref.watch(userNameProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dailyVerseProvider);
              ref.invalidate(dailyImpulsesProvider);
              ref.invalidate(latestContentProvider);
              ref.invalidate(recentContentProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Greeting + Profile Avatar Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      DesignTokens.paddingHorizontal,
                      24,
                      DesignTokens.paddingHorizontal,
                      DesignTokens.spacingMedium,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Greeting Text
                        Text(
                          'Hi, ${userName ?? "User"}',
                          style: GoogleFonts.poppins(
                            textStyle: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ) ?? const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),

                        // Profile Avatar
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileEditScreen(),
                              ),
                            );
                          },
                          child: profileAsync.maybeWhen(
                            data: (profile) => CircleAvatar(
                              radius: 22,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              backgroundImage: profile?.avatarUrl != null
                                  ? CachedNetworkImageProvider(profile!.avatarUrl!)
                                  : null,
                              child: profile?.avatarUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 24,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    )
                                  : null,
                            ),
                            orElse: () => CircleAvatar(
                              radius: 22,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.person,
                                size: 24,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.paddingHorizontal,
                  DesignTokens.spacingMedium,
                  DesignTokens.paddingHorizontal,
                  DesignTokens.spacingSmall,
                ),
                child: Text(
                  'Impulse',
                  style: GoogleFonts.poppins(
                    textStyle: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ) ?? const TextStyle(fontWeight: FontWeight.w700),
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
                    child: Text('Fehler beim Laden der Impulse: $error'),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Latest Content Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.paddingHorizontal,
                  DesignTokens.spacingMedium,
                  DesignTokens.paddingHorizontal,
                  DesignTokens.spacingSmall,
                ),
                child: Text(
                  'Neuester Beitrag',
                  style: GoogleFonts.poppins(
                    textStyle: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ) ?? const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Latest Content
            SliverToBoxAdapter(
              child: latestContentAsync.when(
                data: (latestItem) {
                  if (latestItem == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Kein Inhalt verfügbar')),
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.paddingHorizontal,
                    ),
                    child: RecommendedContentTile(
                      item: latestItem,
                      onTap: () => _navigateToContent(
                        context,
                        latestItem,
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
                    child: Text('Fehler beim Laden: $error'),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Recent Content Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.paddingHorizontal,
                  DesignTokens.spacingMedium,
                  DesignTokens.paddingHorizontal,
                  DesignTokens.spacingSmall,
                ),
                child: Text(
                  'Weitere Beiträge',
                  style: GoogleFonts.poppins(
                    textStyle: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ) ?? const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Recent Content List
            SliverToBoxAdapter(
              child: recentContentAsync.when(
                data: (recentItems) {
                  if (recentItems.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Keine weiteren Beiträge verfügbar')),
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.paddingHorizontal,
                    ),
                    child: Column(
                      children: List.generate(
                        recentItems.length,
                        (index) {
                          final item = recentItems[index];
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
                    child: Text('Fehler beim Laden: $error'),
                  ),
                ),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
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
