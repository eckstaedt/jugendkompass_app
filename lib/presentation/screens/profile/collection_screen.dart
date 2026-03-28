import 'package:flutter/material.dart';
import 'dart:ui';
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
    final brightness = theme.brightness;
    final typeLabel = _getTypeLabel(item.type, translate);
    // Strip HTML tags from title for clean display
    final cleanTitle = _stripHtml(item.title);

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DesignTokens.glassBlurSigma,
              sigmaY: DesignTokens.glassBlurSigma,
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: DesignTokens.getGlassBackground(brightness, 0.26),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
                border: DesignTokens.cardBorder(brightness),
                boxShadow: [DesignTokens.shadowGlass],
              ),
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingSmall),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: DesignTokens.getAppBackground(brightness),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                        boxShadow: [DesignTokens.shadowSubtle],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? CorsNetworkImage(
                                imageUrl: item.imageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : SizedBox(
                                width: 80,
                                height: 80,
                                child: Icon(
                                  _getTypeIcon(item.type),
                                  size: 32,
                                  color: DesignTokens.primaryRed,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingMedium),
                    // Title + Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            cleanTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          BadgeWidget(
                            label: typeLabel.toUpperCase(),
                            backgroundColor: DesignTokens.getRedBackground(brightness),
                            textColor: DesignTokens.primaryRed,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Strip HTML tags from a string
  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
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

  IconData _getTypeIcon(CollectionItemType type) {
    switch (type) {
      case CollectionItemType.impulse:
        return Icons.auto_awesome;
      case CollectionItemType.video:
        return Icons.play_circle_outline;
      case CollectionItemType.post:
        return Icons.article_outlined;
      case CollectionItemType.edition:
        return Icons.menu_book_outlined;
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
