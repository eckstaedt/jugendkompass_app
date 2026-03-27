import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/domain/providers/favorites_provider.dart';
import 'package:jugendkompass_app/domain/providers/content_provider.dart';
import 'package:jugendkompass_app/presentation/screens/content/widgets/content_card.dart';
import 'package:jugendkompass_app/presentation/screens/content/content_detail_screen.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Favoriten'),
        centerTitle: true,
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
          ? EmptyState(
              icon: Icons.favorite_border,
              title: 'Keine Favoriten',
              message: 'Markiere Inhalte als Favoriten, um sie hier zu sehen.',
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(favoritesProvider.notifier).refresh();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
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
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.onError,
                            ),
                          ),
                          onDismissed: (direction) {
                            ref.read(favoritesProvider.notifier).removeFavorite(content.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${content.displayTitle} ${AppTranslations.t('removed_from_favorites')}'),
                                action: SnackBarAction(
                                  label: AppTranslations.t('undo'),
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
              ),
            ),
    );
  }
}
