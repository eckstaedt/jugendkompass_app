import 'package:flutter/material.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/services/verse_share_service.dart';
import 'package:jugendkompass_app/presentation/widgets/verse/verse_share_card.dart';

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

  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareVerse() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    await VerseShareService.shareVerseImage(boundaryKey: _shareCardKey);
    if (mounted) setState(() => _isSharing = false);
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
    return Stack(
      children: [
        // Off-screen share card – rendered but invisible, used for image capture.
        Offstage(
          child: RepaintBoundary(
            key: _shareCardKey,
            child: VerseShareCard(verse: verse),
          ),
        ),

        // Visible interactive card.
        GestureDetector(
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
                onPressed: _isSharing ? null : _shareVerse,
                icon: _isSharing
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
        ), // GestureDetector
      ],
    ); // Stack
  }
}
