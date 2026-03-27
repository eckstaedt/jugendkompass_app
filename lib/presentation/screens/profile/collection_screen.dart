import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/data/models/collection_item_model.dart';
import 'package:jugendkompass_app/domain/providers/collection_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/domain/providers/post_provider.dart';
import 'package:jugendkompass_app/domain/providers/impulse_provider.dart';
import 'package:jugendkompass_app/domain/providers/edition_provider.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart'
    show kEditionDetailRouteName;
import 'package:jugendkompass_app/presentation/screens/post/post_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/impulse/impulse_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/edition_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final translate = ref.watch(stringTranslatorProvider);
    final collectionItems = ref.watch(collectionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Deine Sammlung'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: collectionItems.isNotEmpty
            ? [
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text('Alle löschen'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Sammlung leeren?'),
                            content: Text('Möchtest du wirklich alle Inhalte aus deiner Sammlung löschen?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Abbrechen'),
                              ),
                              FilledButton.tonal(
                                onPressed: () {
                                  ref.read(collectionServiceProvider).clearAllItems();
                                  ref.invalidate(collectionProvider);
                                  Navigator.pop(context);
                                },
                                child: Text('Löschen'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                )
              ]
            : null,
      ),
      body: collectionItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.collections_bookmark_outlined,
                    size: 64,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Deine Sammlung ist leer',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Speichere Inhalte mit dem Lesezeichen-Symbol',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(DesignTokens.paddingHorizontal),
              itemCount: collectionItems.length,
              itemBuilder: (context, index) {
                final item = collectionItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCollectionItemCard(context, item, ref, theme, translate),
                );
              },
            ),
    );
  }

  Widget _buildCollectionItemCard(
    BuildContext context,
    CollectionItem item,
    WidgetRef ref,
    ThemeData theme,
    String Function(String) translate,
  ) {
    final typeEmoji = _getTypeEmoji(item.type);
    final typeLabel = _getTypeLabel(item.type, translate);

    return Dismissible(
      key: Key('${item.id}_${item.type}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(collectionProvider.notifier).removeFromCollection(item.id, item.type);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
          color: Colors.red.withOpacity(0.8),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _navigateToItem(context, ref, item),
        child: RoundedCard(
        padding: const EdgeInsets.all(12),
        glass: true,
        backgroundColor: DesignTokens.glassBackgroundDeep(0.22),
        withShadow: true,
        child: Row(
          children: [
            // Image or icon
            if (item.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                child: CorsNetworkImage(
                  imageUrl: item.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    width: 60,
                    height: 60,
                    color: DesignTokens.getGlassBackground(theme.brightness, 0.2),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: Container(
                    width: 60,
                    height: 60,
                    color: DesignTokens.getGlassBackground(theme.brightness, 0.2),
                    child: const Icon(Icons.broken_image, size: 30),
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                  color: DesignTokens.getGlassBackground(theme.brightness, 0.2),
                ),
                child: Center(
                  child: Text(
                    typeEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: DesignTokens.getGlassBackground(theme.brightness, 0.15),
                        ),
                        child: Text(
                          typeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.author != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'von ${item.author}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _navigateToItem(BuildContext context, WidgetRef ref, CollectionItem item) async {
    switch (item.type) {
      case CollectionItemType.video:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoUrl: item.id,
              title: item.title,
              imageUrl: item.imageUrl,
              description: item.description,
            ),
          ),
        );
        break;
      case CollectionItemType.post:
        final post = await ref.read(postDetailProvider(item.id).future);
        if (post != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          );
        }
        break;
      case CollectionItemType.impulse:
        final impulse = await ref.read(impulseDetailProvider(item.id).future);
        if (impulse != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImpulseDetailScreen(impulse: impulse),
            ),
          );
        }
        break;
      case CollectionItemType.edition:
        final edition = await ref.read(editionDetailProvider(item.id).future);
        if (edition != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: RouteSettings(name: kEditionDetailRouteName),
              builder: (context) => EditionDetailScreen(edition: edition),
            ),
          );
        }
        break;
    }
  }

  String _getTypeEmoji(CollectionItemType type) {
    switch (type) {
      case CollectionItemType.impulse:
        return '✨';
      case CollectionItemType.video:
        return '▶️';
      case CollectionItemType.post:
        return '📄';
      case CollectionItemType.edition:
        return '📖';
    }
  }

  String _getTypeLabel(CollectionItemType type, String Function(String) translate) {
    switch (type) {
      case CollectionItemType.impulse:
        return 'Impuls';
      case CollectionItemType.video:
        return 'Video';
      case CollectionItemType.post:
        return translate('Artikel');
      case CollectionItemType.edition:
        return 'Ausgabe';
    }
  }
}
