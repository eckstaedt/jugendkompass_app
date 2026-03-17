import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/domain/providers/profile_provider.dart';
import 'package:jugendkompass_app/domain/providers/theme_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/favorites_provider.dart';
import 'package:jugendkompass_app/domain/providers/favorite_verses_provider.dart';
import 'package:jugendkompass_app/domain/providers/collection_provider.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/data/services/favorites_service.dart';
import 'package:jugendkompass_app/data/services/favorite_verses_service.dart';
import 'package:jugendkompass_app/data/services/collection_service.dart';
import '../shop/shop_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'favorite_verses_screen.dart';
import 'collection_screen.dart';
import 'package:jugendkompass_app/presentation/screens/search/search_screen.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentLanguage = ref.watch(languageProvider);
    final translations = ref.watch(translationsProvider);
    final translate = ref.watch(stringTranslatorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(translations.get('settings')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.paddingHorizontal, vertical: DesignTokens.spacingMedium),
        children: [
          // App-wide Search Bar
          RoundedCard(
            glass: true,
            backgroundColor: DesignTokens.glassBackgroundDeep(0.20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            withShadow: false,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: DesignTokens.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    translate('Suche in der ganzen App...'),
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: DesignTokens.spacingMedium),

          // Settings Section Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              translate('EINSTELLUNGEN'),
              style: GoogleFonts.inter(
                textStyle: theme.textTheme.labelMedium?.copyWith(
                  color: DesignTokens.textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Notification toggle
          SwitchListTile(
            tileColor: DesignTokens.glassBackground(0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            title: Text(translate('Benachrichtigungen')),
            subtitle: Text(translate('Push-Benachrichtigungen erhalten')),
            value: notificationsEnabled,
            onChanged: (value) {
              ref.read(notificationsProvider.notifier).update(value);
            },
            activeColor: DesignTokens.primaryRed,
            secondary: const Icon(Icons.notifications_outlined),
          ),
          SizedBox(height: DesignTokens.spacingSmall),

          // Dark mode toggle
          SwitchListTile(
            tileColor: DesignTokens.glassBackground(0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            title: Text(translate('Dark Mode')),
            subtitle: Text(translate('Dunkles Theme verwenden')),
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).toggle();
            },
            activeColor: DesignTokens.primaryRed,
            secondary: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode_outlined,
            ),
          ),
          SizedBox(height: DesignTokens.spacingSmall),

          // Language selection with proper design
          ListTile(
            tileColor: DesignTokens.glassBackground(0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: const Icon(Icons.language_outlined),
            title: Text(translate('Sprache')),
            subtitle: Text(currentLanguage.displayName),
            trailing: DropdownButton<AppLanguage>(
              value: currentLanguage,
              onChanged: (AppLanguage? newLanguage) {
                if (newLanguage != null) {
                  ref.read(languageProvider.notifier).setLanguage(newLanguage);
                }
              },
              items: AppLanguage.values.map((lang) {
                return DropdownMenuItem<AppLanguage>(
                  value: lang,
                  child: Text(lang.displayName),
                );
              }).toList(),
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: DesignTokens.primaryRed),
            ),
          ),

          SizedBox(height: DesignTokens.spacingMedium),

          // Favorite Verses Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              translate('VERS DES TAGES'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          ListTile(
            tileColor: DesignTokens.glassBackground(0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers)),
            leading: const Icon(Icons.favorite_outline),
            title: Text(translate('Favoriten')),
            subtitle: Text('${ref.watch(favoriteVersesProvider).length} ${ref.watch(favoriteVersesProvider).length == 1 ? translate('Vers') : translate('Verse')}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoriteVersesScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: DesignTokens.spacingMedium),

          // Collection Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              translate('MEINE INHALTE'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          ListTile(
            tileColor: DesignTokens.glassBackground(0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers)),
            leading: const Icon(Icons.bookmark_outlined),
            title: Text(translate('Deine Sammlung')),
            subtitle: Text('${ref.watch(collectionProvider).length} ${ref.watch(collectionProvider).length == 1 ? translate('Element') : translate('Elemente')}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollectionScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: DesignTokens.spacingSmall),
          // Shop placeholder
          ListTile(
            tileColor: DesignTokens.glassBackground(0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers)),
            leading: const Icon(Icons.storefront_outlined),
            title: Text(translate('Shop')),
            subtitle: Text(translate('Bald verfügbar')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ShopScreen()),
              );
            },
          ),

          const SizedBox(height: DesignTokens.spacingLarge),

          // Danger Zone
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  translate('GEFAHRENBEREICH'),
                  style: GoogleFonts.inter(
                    textStyle: theme.textTheme.labelMedium?.copyWith(
                      color: DesignTokens.primaryRed,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingSmall),
                OutlinedButton.icon(
                  onPressed: () => _showDeleteDataDialog(context, ref, translate),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DesignTokens.primaryRed,
                    side: BorderSide(color: DesignTokens.primaryRed),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusButtons)),
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: Text(translate('Daten löschen')),
                ),
                const SizedBox(height: 8),
                Text(
                  translate('Löscht alle deine lokalen Daten und setzt die App zurück.'),
                  style: GoogleFonts.inter(
                    textStyle: theme.textTheme.bodySmall?.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // App Version (optional)
          Center(
            child: Text(
              'Version 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _showDeleteDataDialog(BuildContext context, WidgetRef ref, String Function(String) translate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate('Daten löschen?')),
        content: Text(
          translate('Möchtest du wirklich alle deine Daten löschen? Diese Aktion kann nicht rückgängig gemacht werden.\n\nFolgende Daten werden gelöscht:\n• Dein Name und Einstellungen\n• Alle Favoriten\n• Bibelleseplan-Fortschritt\n• Dark Mode Einstellung'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(translate('Abbrechen')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(translate('Löschen')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteAllData(context, ref, translate);
    }
  }

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref, String Function(String) translate) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Clear local data
      await UserPreferencesService.instance.clearAll();
      await FavoritesService.instance.clearAllFavorites();
      await FavoriteVersesService.instance.clearAllFavorites();
      await CollectionService.instance.clearAllItems();

      // Delete Supabase data if authenticated
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        try {
          await ref.read(profileRepositoryProvider).deleteUserData(userId);
        } catch (e) {
          // Log error but continue with local deletion
          debugPrint('Failed to delete Supabase data: $e');
        }
      }

      // Reset providers
      ref.invalidate(userNameProvider);
      ref.invalidate(favoritesProvider);
      ref.invalidate(favoriteVersesProvider);
      ref.invalidate(collectionProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(themeModeProvider);

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate back to onboarding
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OnboardingScreen()),
        (route) => false,
      );

      // Show success message
      final successMessage = translate('Alle Daten wurden gelöscht');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog if open
      Navigator.pop(context);

      final errorMessage = '${translate('Fehler beim Löschen')}: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
