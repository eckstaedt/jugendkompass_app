import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/services/verse_share_service.dart';
import 'package:jugendkompass_app/core/utils/snackbar_utils.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

/// A single card in the "Vers des Tages Archiv" list.
///
/// Cards are dynamically sized to always show the entire verse text in
/// full (no truncation) - card height varies with verse length. Sharing as
/// an image is only possible when the verse has an admin-uploaded
/// [VerseModel.imageUrl] - there is no Flutter-rendered fallback here
/// (unlike the home screen card), per design.
class VerseArchiveCard extends StatefulWidget {
  final VerseModel verse;

  const VerseArchiveCard({super.key, required this.verse});

  @override
  State<VerseArchiveCard> createState() => _VerseArchiveCardState();
}

class _VerseArchiveCardState extends State<VerseArchiveCard> {
  bool _isSharing = false;
  bool _isSaving = false;

  bool get _canShare =>
      widget.verse.imageUrl != null && widget.verse.imageUrl!.isNotEmpty;

  Future<void> _shareVerse() async {
    if (_isSharing || !_canShare) return;
    setState(() => _isSharing = true);
    try {
      await VerseShareService.shareVerse(widget.verse);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, context.tr('share_error'));
      }
    }
    if (mounted) setState(() => _isSharing = false);
  }

  Future<void> _saveToGallery() async {
    if (_isSaving || !_canShare) return;
    setState(() => _isSaving = true);

    bool hasAccess = await VerseShareService.hasGalleryAccess();
    if (!hasAccess) {
      hasAccess = await VerseShareService.requestGalleryAccess();
    }

    if (!hasAccess) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          context.tr('gallery_permission_denied'),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    final success = await VerseShareService.saveToGallery(widget.verse);

    if (mounted) {
      if (success) {
        SnackBarUtils.showSuccess(
          context,
          context.tr('image_saved_to_gallery'),
        );
      } else {
        SnackBarUtils.showError(context, context.tr('save_error'));
      }
      setState(() => _isSaving = false);
    }
  }

  void _showShareOptions() {
    if (!_canShare) return;

    if (kIsWeb) {
      _shareVerse();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.getCardBackground(
        Theme.of(context).brightness,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 16,
          bottom:
              DesignTokens.overlayPaddingBase +
              MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(context.tr('share')),
              subtitle: Text(context.tr('share_via_apps')),
              onTap: () {
                Navigator.pop(context);
                _shareVerse();
              },
            ),
            ListTile(
              leading: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_alt_outlined),
              title: Text(context.tr('save_to_gallery')),
              subtitle: Text(context.tr('save_image_to_photos')),
              onTap: _isSaving
                  ? null
                  : () {
                      Navigator.pop(context);
                      _saveToGallery();
                    },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final verse = widget.verse;
    final dateLabel = DateFormat('dd. MMMM yyyy', 'de_DE').format(verse.date);

    return RoundedCard(
      padding: const EdgeInsets.all(DesignTokens.spacingMedium),
      glass: true,
      backgroundColor: DesignTokens.glassBackgroundDeep(0.20),
      withShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: date badge + share icon
          Row(
            children: [
              BadgeWidget(label: dateLabel.toUpperCase()),
              const Spacer(),
              Tooltip(
                message: _canShare
                    ? context.tr('share')
                    : context.tr('no_image_for_verse'),
                child: IconButton(
                  onPressed: (_isSharing || _isSaving || !_canShare)
                      ? null
                      : _showShareOptions,
                  icon: (_isSharing || _isSaving)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.share_outlined,
                          color: _canShare
                              ? null
                              : DesignTokens.getTextSecondary(
                                  brightness,
                                ).withValues(alpha: 0.35),
                        ),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingMedium),
          // Full verse text - never truncated, so the card grows to fit.
          Text(
            verse.verse,
            style: GoogleFonts.merriweather(
              textStyle:
                  theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ) ??
                  const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${verse.reference}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: DesignTokens.getTextSecondary(brightness),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
