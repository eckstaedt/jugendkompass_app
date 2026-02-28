import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/edition_provider.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/widgets/edition_card.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

class KioskScreen extends ConsumerWidget {
  const KioskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editionsAsync = ref.watch(editionsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: DesignTokens.appBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(editionsListProvider);
          },
          child: editionsAsync.when(
            data: (editions) {
              if (editions.isEmpty) {
                return const EmptyState(
                  icon: Icons.compass_calibration_outlined,
                  title: 'Keine Magazine verfügbar',
                  message: 'Schau später noch einmal vorbei',
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
                        16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kiosk',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Alle Ausgaben',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: DesignTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Magazine Grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.paddingHorizontal,
                      DesignTokens.spacingMedium,
                      DesignTokens.paddingHorizontal,
                      80,
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
            loading: () => const LoadingIndicator(
              message: 'Lade Magazine...',
            ),
            error: (error, stack) => ErrorView(
              message: 'Fehler beim Laden der Magazine: $error',
              onRetry: () => ref.invalidate(editionsListProvider),
            ),
          ),
        ),
      ),
    );
  }
}
