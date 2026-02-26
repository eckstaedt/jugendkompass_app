import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/edition_provider.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/widgets/edition_card.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';

class KioskScreen extends ConsumerWidget {
  const KioskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editionsAsync = ref.watch(editionsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3F0), // Beige background
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(editionsListProvider);
          },
          child: editionsAsync.when(
            data: (editions) {
              if (editions.isEmpty) {
                return const EmptyState(
                  icon: Icons.library_books_outlined,
                  title: 'Keine Magazine verfügbar',
                  message: 'Schau später noch einmal vorbei',
                );
              }

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kiosk',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Alle Ausgaben',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Magazine Grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65, // Portrait covers
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 16,
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
