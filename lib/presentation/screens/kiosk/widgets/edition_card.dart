import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/edition_model.dart';
import 'package:jugendkompass_app/data/models/collection_item_model.dart';
import 'package:jugendkompass_app/domain/providers/collection_provider.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/edition_detail_screen.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

class EditionCard extends ConsumerWidget {
  final EditionModel edition;

  const EditionCard({
    super.key,
    required this.edition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isInCollection = ref.watch(collectionProvider).any(
          (item) => item.id == edition.id && item.type == CollectionItemType.edition,
        );
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditionDetailScreen(edition: edition),
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Cover Image with rounded corners - LARGE BORDER RADIUS
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
                    boxShadow: [DesignTokens.shadowGlass],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
                    child: edition.coverImageUrl != null
                        ? CorsNetworkImage(
                            imageUrl: edition.coverImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: Container(
                              color: DesignTokens.appBackground,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: DesignTokens.primaryRed,
                                ),
                              ),
                            ),
                            errorWidget: Container(
                              color: DesignTokens.appBackground,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.library_books,
                                    size: 48,
                                    color: DesignTokens.textSecondary,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Cover nicht verfügbar',
                                    style: TextStyle(
                                      color: DesignTokens.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            color: DesignTokens.appBackground,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.library_books,
                                  size: 48,
                                  color: DesignTokens.textSecondary,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Cover nicht verfügbar',
                                  style: TextStyle(
                                    color: DesignTokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                // Save Button (top right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      final item = CollectionItem(
                        id: edition.id,
                        title: edition.displayTitle,
                        description: edition.body,
                        imageUrl: edition.coverImageUrl,
                        type: CollectionItemType.edition,
                        savedAt: DateTime.now(),
                      );
                      ref.read(collectionProvider.notifier).toggleCollection(item);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isInCollection ? Icons.bookmark : Icons.bookmark_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.spacingSmall),

          // Title
          Text(
            edition.displayTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        ),
      ),
    );
  }
}
