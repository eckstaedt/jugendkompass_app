import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/domain/providers/favorite_verses_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

class FavoriteVersesScreen extends ConsumerWidget {
  const FavoriteVersesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final translate = ref.watch(stringTranslatorProvider);
    final favoriteVerses = ref.watch(favoriteVersesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('favorite_verses_title')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: favoriteVerses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    translate('Keine favorisierten Verse'),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    translate('Like den Vers des Tages um ihn hier zu speichern'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(DesignTokens.paddingHorizontal),
              itemCount: favoriteVerses.length,
              itemBuilder: (context, index) {
                final verse = favoriteVerses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(translate('remove_verse')),
                          content: Text(translate('remove_verse_confirmation')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Abbrechen'),
                            ),
                            FilledButton.tonal(
                              onPressed: () {
                                ref.read(favoriteVersesProvider.notifier).removeFavoriteVerse(verse.id);
                                Navigator.pop(context);
                              },
                              child: Text(translate('delete_all')),
                            ),
                          ],
                        ),
                      );
                    },
                    child: RoundedCard(
                      padding: const EdgeInsets.all(DesignTokens.spacingMedium),
                      glass: true,
                      backgroundColor: DesignTokens.glassBackgroundDeep(0.15),
                      withShadow: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Verse text
                          Text(
                            '"${verse.verse}"',
                            style: GoogleFonts.merriweather(
                              textStyle: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ) ??
                                  const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Reference
                          Text(
                            '— ${verse.reference}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          // Date hint
                          const SizedBox(height: 8),
                          Text(
                            'Von: ${verse.date.day}.${verse.date.month}.${verse.date.year}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
