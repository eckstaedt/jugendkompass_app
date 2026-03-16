import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/domain/providers/favorite_verses_provider.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

class VerseCard extends ConsumerWidget {
  final VerseModel verse;

  const VerseCard({
    super.key,
    required this.verse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favoriteVerses = ref.watch(favoriteVersesProvider);
    final isFavorite = favoriteVerses.any((v) => v.id == verse.id);

    return RoundedCard(
      padding: const EdgeInsets.all(DesignTokens.spacingMedium),
      glass: true,
      backgroundColor: DesignTokens.glassBackgroundDeep(0.24),
      withShadow: false, // Glass effect already has shadow via BackdropFilter
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with label and favorite icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BadgeWidget(
                label: 'VERS DES TAGES',
                backgroundColor: DesignTokens.redBackground,
                textColor: DesignTokens.primaryRed,
              ),
              // Favorite icon (top right)
              GestureDetector(
                onTap: () {
                  ref.read(favoriteVersesProvider.notifier).toggleFavoriteVerse(verse);
                },
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: DesignTokens.primaryRed,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingMedium),
          // Verse text itself uses Merriweather (serif) per design request.
          Text(
            '"${verse.verse}"',
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
              color: DesignTokens.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
