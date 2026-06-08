import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/presentation/screens/shop/subscription_form_screen.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final translate = ref.watch(stringTranslatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Shop')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.paddingHorizontal,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Magazine image
              Image.asset(
                'assets/images/shop_magazines.png',
                width: 260,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 32),

              // Headline
              Text(
                translate('Das Heft bequem zu dir nach Hause bestellen'),
                style: GoogleFonts.poppins(
                  textStyle: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subline
              Text(
                translate('Rund um die Uhr – kostenlos & frei Haus'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: DesignTokens.getTextSecondary(brightness),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Highlight chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _InfoChip(icon: Icons.local_shipping_outlined, label: translate('Kostenloser Versand')),
                  _InfoChip(icon: Icons.euro_outlined, label: translate('Kostenlos')),
                  _InfoChip(icon: Icons.schedule_outlined, label: translate('Rund um die Uhr')),
                ],
              ),

              const Spacer(),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionFormScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    translate('Jetzt bestellen'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                translate('Keine Zahlung erforderlich'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DesignTokens.getTextSecondary(brightness),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DesignTokens.getGlassBackground(brightness, 0.18),
        borderRadius: BorderRadius.circular(20),
        border: DesignTokens.cardBorder(brightness),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DesignTokens.primaryRed),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
