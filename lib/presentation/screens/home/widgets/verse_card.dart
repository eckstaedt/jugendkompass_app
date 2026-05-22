import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/services/verse_share_service.dart';
import 'package:jugendkompass_app/core/utils/snackbar_utils.dart';

class VerseCard extends StatefulWidget {
  final VerseModel verse;

  const VerseCard({
    super.key,
    required this.verse,
  });

  @override
  State<VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends State<VerseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isSharing = false;
  bool _isSaving = false;

  Future<void> _shareVerse() async {
    if (_isSharing) return;
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
    if (_isSaving) return;
    setState(() => _isSaving = true);

    // Check/request permission
    bool hasAccess = await VerseShareService.hasGalleryAccess();
    if (!hasAccess) {
      hasAccess = await VerseShareService.requestGalleryAccess();
    }

    if (!hasAccess) {
      if (mounted) {
        SnackBarUtils.showError(context, context.tr('gallery_permission_denied'));
      }
      setState(() => _isSaving = false);
      return;
    }

    final success = await VerseShareService.saveToGallery(widget.verse);

    if (mounted) {
      if (success) {
        SnackBarUtils.showSuccess(context, context.tr('image_saved_to_gallery'));
      } else {
        SnackBarUtils.showError(context, context.tr('save_error'));
      }
      setState(() => _isSaving = false);
    }
  }

  void _showShareOptions() {
    // On web, just share directly (no gallery save option)
    if (kIsWeb) {
      _shareVerse();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.getCardBackground(Theme.of(context).brightness),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 16,
          bottom: DesignTokens.overlayPaddingBase + MediaQuery.of(context).padding.bottom,
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
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verse = widget.verse;

    // The verse is already localized from the RPC function get_verse_of_day_localized
    // in verse_repository.dart, so we just display it directly without additional translation
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: RoundedCard(
            padding: const EdgeInsets.all(DesignTokens.spacingMedium),
            glass: true,
            backgroundColor: DesignTokens.glassBackgroundDeep(0.30),
            withShadow: true,
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with label and share icon
          Row(
            children: [
              BadgeWidget(
                label: context.tr('verse_of_day_badge'),
              ),
              const Spacer(),
              IconButton(
                onPressed: (_isSharing || _isSaving) ? null : _showShareOptions,
                icon: (_isSharing || _isSaving)
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share_outlined),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Teilen',
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingMedium),
          // Verse text itself uses Merriweather (serif) per design request.
          Text(
            verse.verse,
            style: GoogleFonts.merriweather(
              textStyle: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ) ??
                  const TextStyle(fontWeight: FontWeight.w600, height: 1.5),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMedium),
          Text(
            '— ${verse.reference}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: DesignTokens.getTextSecondary(theme.brightness),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
            ),
          ),
        ),
      ),
    );
  }
}
