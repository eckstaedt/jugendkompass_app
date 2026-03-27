import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/domain/providers/profile_provider.dart';
import 'package:jugendkompass_app/domain/providers/theme_provider.dart';
import 'package:jugendkompass_app/domain/providers/favorites_provider.dart';
import 'package:jugendkompass_app/domain/providers/collection_provider.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/data/services/favorites_service.dart';

import 'package:jugendkompass_app/data/services/collection_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../onboarding/onboarding_screen.dart';
import 'collection_screen.dart';
import 'package:jugendkompass_app/presentation/screens/search/search_screen.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final translate = ref.watch(stringTranslatorProvider);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final textSecondary = DesignTokens.getTextSecondary(brightness);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
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
                    color: textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    translate('Suche in der ganzen App...'),
                    style: TextStyle(
                      color: textSecondary,
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
                  color: textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Notification toggle
          SwitchListTile(
            tileColor: DesignTokens.getGlassBackground(theme.brightness, 0.22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
              side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            title: Text(translate('Benachrichtigungen')),
            subtitle: Text(translate('Push-Benachrichtigungen erhalten')),
            value: notificationsEnabled,
            onChanged: (value) {
              ref.read(notificationsProvider.notifier).update(value);
            },
            activeThumbColor: DesignTokens.primaryRed,
            secondary: const Icon(Icons.notifications_outlined),
          ),
          SizedBox(height: DesignTokens.spacingSmall),

          // Dark mode toggle
          SwitchListTile(
            tileColor: DesignTokens.getGlassBackground(theme.brightness, 0.22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
              side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            title: Text(translate('Dark Mode')),
            subtitle: Text(translate('Dunkles Theme verwenden')),
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).toggle();
            },
            activeThumbColor: DesignTokens.primaryRed,
            secondary: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode_outlined,
            ),
          ),
          SizedBox(height: DesignTokens.spacingSmall),

          // Name editing
          ListTile(
            tileColor: DesignTokens.getGlassBackground(theme.brightness, 0.22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
              side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: const Icon(Icons.person_outline),
            title: Text(translate('Name')),
            subtitle: Text(ref.watch(userNameProvider) ?? translate('Nicht festgelegt')),
            trailing: const Icon(Icons.edit_outlined, size: 20),
            onTap: () => _showNameEditDialog(context, ref, translate),
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
            tileColor: DesignTokens.getGlassBackground(theme.brightness, 0.22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
              side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
            ),
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
          // Shop – opens external website
          ListTile(
            tileColor: DesignTokens.getGlassBackground(theme.brightness, 0.22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
              side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
            ),
            leading: const Icon(Icons.storefront_outlined),
            title: Text(translate('Shop')),
            subtitle: const Text('stephanus-verlag.de'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () async {
              final uri = Uri.parse('https://stephanus-verlag.de/');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
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
                      color: textSecondary,
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

  Future<void> _showNameEditDialog(BuildContext context, WidgetRef ref, String Function(String) translate) async {
    final currentName = ref.watch(userNameProvider) ?? '';
    final controller = TextEditingController(text: currentName);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate('Name ändern')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: translate('Dein Name'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translate('Abbrechen')),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.length >= 2) {
                Navigator.pop(context, name);
              }
            },
            child: Text(translate('Speichern')),
          ),
        ],
      ),
    );
    
    if (newName != null && newName.isNotEmpty && context.mounted) {
      await UserPreferencesService.instance.setUserName(newName);
      ref.read(userNameProvider.notifier).state = newName;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate('Name gespeichert')),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
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
