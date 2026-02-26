import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/favorites_provider.dart';
import 'package:jugendkompass_app/domain/providers/content_provider.dart';
import 'package:jugendkompass_app/presentation/screens/content/widgets/content_card.dart';
import 'package:jugendkompass_app/presentation/screens/content/content_detail_screen.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';

class SammlungScreen extends ConsumerWidget {
  const SammlungScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deine Sammlung'),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(favoritesProvider.notifier).refresh();
              },
            ),
        ],
      ),
      body: favorites.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border,
              title: 'Keine Favoriten',
              message: 'Markiere Inhalte als Favoriten, um sie hier zu sehen.',
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(favoritesProvider.notifier).refresh();
              },
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${favorites.length} ${favorites.length == 1 ? 'Favorit' : 'Favoriten'}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content List
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final favoriteId = favorites[index];
                          final contentAsync = ref.watch(contentDetailProvider(favoriteId));

                          return contentAsync.when(
                            data: (content) {
                              if (content == null) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Dismissible(
                                  key: Key(content.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: theme.colorScheme.onError,
                                    ),
                                  ),
                                  onDismissed: (direction) {
                                    ref.read(favoritesProvider.notifier).removeFavorite(content.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${content.displayTitle} aus Favoriten entfernt'),
                                        action: SnackBarAction(
                                          label: 'Rückgängig',
                                          onPressed: () {
                                            ref.read(favoritesProvider.notifier).toggleFavorite(content.id);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: ContentCard(
                                    content: content,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ContentDetailScreen(
                                            contentId: content.id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Card(
                                child: SizedBox(
                                  height: 200,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                              ),
                            ),
                            error: (_, _) => const SizedBox.shrink(),
                          );
                        },
                        childCount: favorites.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
