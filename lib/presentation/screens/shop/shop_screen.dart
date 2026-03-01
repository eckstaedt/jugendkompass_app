import 'package:flutter/material.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: DesignTokens.textPrimary,
      ),
      backgroundColor: DesignTokens.appBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.paddingHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 80,
                color: theme.colorScheme.onBackground.withOpacity(0.4),
              ),
              const SizedBox(height: DesignTokens.spacingLarge),
              Text(
                'Der Shop wird bald verfügbar sein!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacingMedium),
              Text(
                'Bis dahin kannst du dich zurücklehnen und dich auf neue Angebote freuen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
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
