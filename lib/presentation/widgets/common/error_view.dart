import 'package:flutter/material.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  /// Network problems get a calm "no connection" view with Psalm 50,15.
  static bool isOffline(String m) {
    final t = m.toLowerCase();
    return t.contains('socketexception') || t.contains('failed host lookup') ||
        t.contains('clientexception') || t.contains('network is unreachable') ||
        t.contains('connection refused') || t.contains('connection closed') ||
        t.contains('timed out') || t.contains('xmlhttprequest error');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (isOffline(message)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 52, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 14),
              Text(AppTranslations.t('no_connection'),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 22),
              Text(AppTranslations.t('offline_verse'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(height: 1.45, fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              Text(AppTranslations.t('offline_verse_ref'),
                  style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w700, color: colorScheme.primary)),
              if (onRetry != null) ...[
                const SizedBox(height: 26),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppTranslations.t('try_again')),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppTranslations.t('error'),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(AppTranslations.t('try_again')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
