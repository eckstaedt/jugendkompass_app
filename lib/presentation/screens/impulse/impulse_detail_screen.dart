import 'package:jugendkompass_app/core/config/app_fonts.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:jugendkompass_app/core/utils/snackbar_utils.dart';
import 'package:jugendkompass_app/core/services/impulse_share_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:jugendkompass_app/data/models/impulse_model.dart';
import 'package:jugendkompass_app/data/models/collection_item_model.dart';
import 'package:jugendkompass_app/data/models/read_history_item_model.dart';
import 'package:jugendkompass_app/domain/providers/collection_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/read_history_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/services/content_share_service.dart';
import 'package:jugendkompass_app/core/utils/html_utils.dart';
import 'package:jugendkompass_app/domain/providers/post_view_count_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/like_button.dart';


class ImpulseDetailScreen extends ConsumerStatefulWidget {
  final ImpulseModel impulse;

  const ImpulseDetailScreen({
    super.key,
    required this.impulse,
  });

  @override
  ConsumerState<ImpulseDetailScreen> createState() => _ImpulseDetailScreenState();
}

class _ImpulseDetailScreenState extends ConsumerState<ImpulseDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Mark impulse as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readHistoryProvider.notifier).markAsRead(
        widget.impulse.id,
        ReadContentType.impulse,
        title: HtmlUtils.stripHtml(widget.impulse.displayTitle),
        imageUrl: widget.impulse.imageUrl,
      );
    });
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M Aufrufe';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k Aufrufe';
    return '$count Aufrufe';
  }

  /// Share sheet: as image (Instagram etc.), save to photos, or link.
  void _showShareOptions(BuildContext context, ImpulseModel impulse, VoidCallback shareLink) {
    final brightness = Theme.of(context).brightness;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.getCardBackground(brightness),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLarge)),
      ),
      builder: (sheetContext) => Padding(
        // Leave room for the floating navbar.
        padding: const EdgeInsets.only(top: 8, bottom: DesignTokens.overlayPaddingBase - 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(context.tr('share_as_image')),
              subtitle: Text(context.tr('share_as_image_subtitle')),
              onTap: () async {
                Navigator.pop(sheetContext);
                try {
                  await ImpulseShareService.shareImage(impulse);
                } catch (_) {
                  if (context.mounted) SnackBarUtils.showError(context, context.tr('error'));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt_outlined),
              title: Text(context.tr('save_to_gallery')),
              subtitle: Text(context.tr('save_image_to_photos')),
              onTap: () async {
                Navigator.pop(sheetContext);
                final ok = await ImpulseShareService.saveToGallery(impulse);
                if (!context.mounted) return;
                ok
                    ? SnackBarUtils.showSuccess(context, context.tr('image_saved_to_gallery'))
                    : SnackBarUtils.showError(context, context.tr('gallery_permission_denied'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: Text(context.tr('share_link')),
              subtitle: Text(context.tr('share_via_apps')),
              onTap: () {
                Navigator.pop(sheetContext);
                shareLink();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final impulse = widget.impulse;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd. MMMM yyyy', 'de_DE');
    final isInCollection = ref.watch(collectionProvider).any(
          (item) => item.id == impulse.id && item.type == CollectionItemType.impulse,
        );

    final displayTitle = impulse.displayTitle;
    final displayBody = impulse.impulseText;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          HtmlUtils.stripHtml(displayTitle),
          style: AppFonts.uiStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: context.tr('share'),
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              void shareLink() => ContentShareService.shareContent(
                    contentType: 'impulse',
                    contentId: impulse.contentId,
                    title: HtmlUtils.stripHtml(displayTitle),
                    intro: context.tr('share_intro_impulse'),
                  );
              if (ImpulseShareService.canShareImage(impulse)) {
                _showShareOptions(context, impulse, shareLink);
              } else {
                shareLink();
              }
            },
          ),
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
                // Square (1:1) cover, like the cards in the lists.
                child: Align(
                  // 1:1 cover a bit smaller, so the text starts higher
                  child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: AspectRatio(
                  aspectRatio: 1,
                  child: CorsNetworkImage(
                    imageUrl: impulse.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ))),
              ),
              const SizedBox(height: 20),
            ],
            // Title
            Text(
              HtmlUtils.stripHtml(displayTitle),
              style: AppFonts.uiStyle(
                textStyle: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Meta information: one quiet line (duration · date · views) + like
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final views = ref.watch(postViewCountProvider(impulse.id)).valueOrNull ?? 0;
                      final parts = <String>[
                        '${impulse.durationMinutes} ${context.tr('min')}',
                        dateFormat.format(impulse.date),
                        if (views > 0) _formatViewCount(views),
                      ];
                      return Text(
                        parts.join('  ·  '),
                        style: AppFonts.uiStyle(
                          textStyle: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                LikeButton(contentId: impulse.id, contentType: 'impulse'),
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
