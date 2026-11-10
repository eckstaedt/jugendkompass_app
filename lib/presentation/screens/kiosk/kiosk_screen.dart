import 'package:jugendkompass_app/presentation/widgets/common/page_header.dart';
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

              // Sort newest first
              final sorted = [...editions]
                ..sort((a, b) => b.publishedDate.compareTo(a.publishedDate));

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: PageHeader(title: translate('Alle Ausgaben')),
                  ),

                  // Magazine Grid
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      DesignTokens.paddingHorizontal,
                      0,
                      DesignTokens.paddingHorizontal,
                      ref.watch(currentAudioProvider) != null
                          ? DesignTokens.overlayPaddingWithMiniPlayer
                          : DesignTokens.overlayPaddingBase,
                    ),
                    sliver: SliverGrid(
                      // Row height follows the real cover width: A4 cover
                      // + gap + two title lines, so nothing overflows on
                      // wide phones and there are no gaps on narrow ones.
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: (MediaQuery.sizeOf(context).width -
                                    3 * DesignTokens.paddingHorizontal) /
                                2 *
                                1.414 +
                            DesignTokens.spacingSmall +
                            48,
                        mainAxisSpacing: DesignTokens.spacingMedium,
                        crossAxisSpacing: DesignTokens.paddingHorizontal,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return EditionCard(edition: sorted[index]);
                        },
                        childCount: sorted.length,
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
