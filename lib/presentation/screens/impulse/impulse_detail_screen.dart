import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:jugendkompass_app/data/models/impulse_model.dart';
import 'package:jugendkompass_app/data/models/collection_item_model.dart';
import 'package:jugendkompass_app/domain/providers/collection_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/translation_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/utils/html_utils.dart';

import 'package:google_fonts/google_fonts.dart';

class ImpulseDetailScreen extends ConsumerWidget {
  final ImpulseModel impulse;

  const ImpulseDetailScreen({
    super.key,
    required this.impulse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd. MMMM yyyy', 'de_DE');
    final isInCollection = ref.watch(collectionProvider).any(
          (item) => item.id == impulse.id && item.type == CollectionItemType.impulse,
        );

    // Translate impulse content to the selected app language
    final translationAsync = ref.watch(
      translateImpulseProvider((
        id: impulse.id,
        title: impulse.title,
        impulseText: impulse.impulseText,
      )),
    );
    final displayTitle = translationAsync.whenOrNull(data: (d) => d.title) ?? impulse.displayTitle;
    final displayBody = translationAsync.whenOrNull(data: (d) => d.impulseText) ?? impulse.impulseText;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          'Impuls',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final item = CollectionItem(
                    id: impulse.id,
                    title: HtmlUtils.stripHtml(displayTitle),
                    description: HtmlUtils.stripAndTruncate(displayBody, maxLength: 200),
                    imageUrl: impulse.imageUrl,
                    type: CollectionItemType.impulse,
                    author: impulse.title,
                    savedAt: DateTime.now(),
                  );
                  ref.read(collectionProvider.notifier).toggleCollection(item);
                },
                child: Icon(
                  isInCollection ? Icons.bookmark : Icons.bookmark_outline,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.paddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if available
            if (impulse.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
                child: CorsNetworkImage(
                  imageUrl: impulse.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Title
            Text(
              HtmlUtils.stripHtml(displayTitle),
              style: GoogleFonts.poppins(
                textStyle: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Meta information
            Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusBadges),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              impulse.durationLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusBadges),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateFormat.format(impulse.date),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // HTML Content
                  Html(
                    data: displayBody,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(18),
                        lineHeight: const LineHeight(1.8),
                        color: theme.colorScheme.onSurface,
                      ),
                      "p": Style(
                        margin: Margins.only(bottom: 16),
                        fontSize: FontSize(18),
                        lineHeight: const LineHeight(1.8),
                      ),
                      "h1": Style(
                        fontSize: FontSize(28),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(bottom: 12, top: 24),
                      ),
                      "h2": Style(
                        fontSize: FontSize(24),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(bottom: 10, top: 20),
                      ),
                      "h3": Style(
                        fontSize: FontSize(20),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(bottom: 8, top: 16),
                      ),
                      "a": Style(
                        color: theme.colorScheme.primary,
                        textDecoration: TextDecoration.underline,
                      ),
                      "ul": Style(
                        margin: Margins.only(left: 20, bottom: 16),
                      ),
                      "ol": Style(
                        margin: Margins.only(left: 20, bottom: 16),
                      ),
                      "li": Style(
                        margin: Margins.only(bottom: 8),
                      ),
                      "blockquote": Style(
                        margin: Margins.only(left: 16, top: 16, bottom: 16),
                        padding: HtmlPaddings.only(left: 16),
                        border: Border(
                          left: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 4,
                          ),
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                      "strong": Style(
                        fontWeight: FontWeight.bold,
                      ),
                      "em": Style(
                        fontStyle: FontStyle.italic,
                      ),
                      "img": Style(
                        display: Display.none,
                      ),
                    },
                  ),

            Consumer(
              builder: (context, ref, _) {
                final hasAudio = ref.watch(currentAudioProvider) != null;
                return SizedBox(
                  height: hasAudio
                      ? DesignTokens.overlayPaddingWithMiniPlayer
                      : DesignTokens.overlayPaddingBase,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
