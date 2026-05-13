import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final translate = ref.watch(stringTranslatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Shop')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.paddingHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 80,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: DesignTokens.spacingLarge),
              Text(
                translate('Der Shop wird bald verfügbar sein!'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacingMedium),
              Text(
                translate('Bis dahin kannst du dich zurücklehnen und dich auf neue Angebote freuen.'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
