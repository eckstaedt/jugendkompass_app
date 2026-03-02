import 'package:flutter/material.dart';
import 'package:jugendkompass_app/data/models/edition_model.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/edition_detail_screen.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

class EditionCard extends StatelessWidget {
  final EditionModel edition;

  const EditionCard({
    super.key,
    required this.edition,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
                boxShadow: [DesignTokens.shadowLargeCard],
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
    );
  }
}
