import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/domain/providers/verse_provider.dart';
import 'package:jugendkompass_app/presentation/screens/verse/widgets/verse_archive_card.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/widgets/common/skeleton_loading.dart';

/// "Vers des Tages Archiv" - lists every verse that has ever been the verse
/// of the day, newest first, each shown on a uniformly-sized card with its
/// date. Supports pull-to-refresh and infinite scroll.
class VerseArchiveScreen extends ConsumerWidget {
  const VerseArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verseArchiveProvider);
    final notifier = ref.read(verseArchiveProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('verse_archive_title')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    VerseArchiveState state,
    VerseArchiveNotifier notifier,
  ) {
    // Only show the full-screen skeleton on the very first load - a
    // pull-to-refresh keeps showing the existing list while it reloads.
    if (state.isLoading && state.verses.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (state.error != null && state.verses.isEmpty) {
      return ErrorView(
        message: context.tr('verse_archive_load_error'),
        onRetry: notifier.refresh,
      );
    }

    if (state.verses.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >
                  scrollInfo.metrics.maxScrollExtent - 300 &&
              state.hasMore &&
              !state.isLoadingMore) {
            notifier.loadMore();
          }
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            DesignTokens.paddingHorizontal,
            DesignTokens.spacingSmall,
            DesignTokens.paddingHorizontal,
            DesignTokens.overlayPaddingBase,
          ),
          itemCount: state.verses.length + (state.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (index >= state.verses.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return VerseArchiveCard(verse: state.verses[index]);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.paddingHorizontal,
        DesignTokens.spacingSmall,
        DesignTokens.paddingHorizontal,
        DesignTokens.overlayPaddingBase,
      ),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => SkeletonShimmer(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SkeletonBox(width: 110, height: 20, radius: 20),
              const SizedBox(height: 20),
              const SkeletonBox(width: double.infinity, height: 16, radius: 4),
              const SizedBox(height: 8),
              const SkeletonBox(width: double.infinity, height: 16, radius: 4),
              const SizedBox(height: 8),
              const SkeletonBox(width: 160, height: 16, radius: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: DesignTokens.getTextSecondary(
                brightness,
              ).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('verse_archive_empty'),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
