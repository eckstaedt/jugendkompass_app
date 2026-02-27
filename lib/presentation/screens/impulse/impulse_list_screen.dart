import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jugendkompass_app/data/models/impulse_model.dart';
import 'package:jugendkompass_app/domain/providers/impulse_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/loading_indicator.dart';
import 'package:jugendkompass_app/presentation/widgets/common/error_view.dart';
import 'package:jugendkompass_app/presentation/widgets/common/empty_state.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'impulse_detail_screen.dart';

class ImpulseListScreen extends ConsumerWidget {
  const ImpulseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impulsesAsync = ref.watch(dailyImpulsesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impulse'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyImpulsesProvider);
        },
        child: impulsesAsync.when(
          data: (impulses) {
            if (impulses.isEmpty) {
              return const EmptyState(
                icon: Icons.lightbulb_outline,
                title: 'Keine Impulse verfügbar',
                message: 'Aktuell gibt es keine Impulse zum Anzeigen.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: impulses.length,
              itemBuilder: (context, index) {
                final impulse = impulses[index];
                return _ImpulseListItem(
                  impulse: impulse,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImpulseDetailScreen(
                          impulse: impulse,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const LoadingIndicator(
            message: 'Lade Impulse...',
          ),
          error: (error, stack) => ErrorView(
            message: 'Fehler beim Laden der Impulse: $error',
            onRetry: () => ref.invalidate(dailyImpulsesProvider),
          ),
        ),
      ),
    );
  }
}

class _ImpulseListItem extends StatelessWidget {
  final ImpulseModel impulse;
  final VoidCallback onTap;

  const _ImpulseListItem({
    required this.impulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd. MMM yyyy', 'de_DE');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image thumbnail
            SizedBox(
              width: 120,
              height: 140,
              child: impulse.imageUrl != null
                  ? CorsNetworkImage(
                      imageUrl: impulse.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.lightbulb_outline,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.lightbulb_outline,
                        size: 40,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      impulse.displayTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateFormat.format(impulse.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Duration
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          impulse.durationLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Read button
                    FilledButton.tonalIcon(
                      onPressed: onTap,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Lesen'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
