import 'package:flutter/material.dart';
import 'package:jugendkompass_app/domain/providers/recommendation_provider.dart';

class RecommendedContentTile extends StatelessWidget {
  final RecommendedItem item;
  final VoidCallback? onTap;

  const RecommendedContentTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const primaryColor = Color(0xFF8B3A3A);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon container (left)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForContentType(item.contentType),
                  size: 32,
                  color: primaryColor,
                ),
              ),

              const SizedBox(width: 16),

              // Title and badge (center)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Content-Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getContentTypeLabel(item.contentType),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron icon (right)
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForContentType(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'audio':
        return Icons.music_note;
      case 'video':
        return Icons.play_circle_outline;
      case 'post':
        return Icons.article_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _getContentTypeLabel(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'audio':
        return 'AUDIO';
      case 'video':
        return 'VIDEO';
      case 'post':
        return 'ARTIKEL';
      default:
        return contentType.toUpperCase();
    }
  }
}
