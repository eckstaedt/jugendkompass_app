import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/edition_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/widgets/edition_card.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/widgets/common/skeleton_loading.dart';

class KioskScreen extends ConsumerWidget {
  const KioskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final translate = ref.watch(stringTranslatorProvider);
    final editionsAsync = ref.watch(editionsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(editionsListProvider);
          },
          child: editionsAsync.when(
            data: (editions) {
              if (editions.isEmpty) {
                return EmptyState(
                  icon: Icons.explore_outlined,
                  title: translate('Keine Magazine verfügbar'),
                  message: translate('Schau später noch einmal vorbei'),
                );
              }

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.paddingHorizontal,
                        40,
                        DesignTokens.paddingHorizontal,
                        24,
                      ),
                      child: Text(
                        translate('Alle Ausgaben'),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  // Magazine Grid
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      DesignTokens.paddingHorizontal,
                      DesignTokens.spacingMedium,
                      DesignTokens.paddingHorizontal,
                      ref.watch(currentAudioProvider) != null
                          ? DesignTokens.overlayPaddingWithMiniPlayer
                          : DesignTokens.overlayPaddingBase,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        mainAxisSpacing: DesignTokens.spacingLarge,
                        crossAxisSpacing: DesignTokens.paddingHorizontal,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return EditionCard(edition: editions[index]);
                        },
                        childCount: editions.length,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const KioskGridSkeleton(),
            error: (error, stack) => ErrorView(
              message: '${translate('Fehler beim Laden der Magazine')}: $error',
              onRetry: () => ref.invalidate(editionsListProvider),
            ),
          ),
        ),
      ),
    );
  }
}
