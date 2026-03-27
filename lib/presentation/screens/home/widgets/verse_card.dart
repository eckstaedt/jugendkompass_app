import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/domain/providers/translation_provider.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

class VerseCard extends ConsumerStatefulWidget {
  final VerseModel verse;

  const VerseCard({
    super.key,
    required this.verse,
  });

  @override
  ConsumerState<VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends ConsumerState<VerseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

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

    // Translate verse content to the selected app language
    final translationAsync = ref.watch(
      translateVerseProvider((verse: verse.verse, reference: verse.reference)),
    );

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
          // Header with label and favorite icon
          BadgeWidget(
                label: 'VERS DES TAGES',
                backgroundColor: DesignTokens.redBackground,
                textColor: DesignTokens.primaryRed,
              ),
          const SizedBox(height: DesignTokens.spacingMedium),
          // Verse text itself uses Merriweather (serif) per design request.
          Text(
            '"${translationAsync.whenOrNull(data: (d) => d.verse) ?? verse.verse}"',
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
            '— ${translationAsync.whenOrNull(data: (d) => d.reference) ?? verse.reference}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: DesignTokens.textSecondary,
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
