import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/domain/providers/profile_provider.dart';
import 'package:jugendkompass_app/domain/providers/theme_provider.dart';
import 'package:jugendkompass_app/domain/providers/favorites_provider.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/data/services/favorites_service.dart';
import 'widgets/profile_header.dart';
import 'profile_edit_screen.dart';
import '../onboarding/onboarding_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final notificationsEnabled = ref.watch(notificationsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final favoritesCount = ref.watch(favoritesProvider).length;
    final theme = Theme.of(context);

    // Get avatar URL from Supabase profile
    final profileAsync = ref.watch(currentUserProfileProvider);
    final avatarUrl = profileAsync.maybeWhen(
      data: (profile) => profile?.avatarUrl,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: ListView(
        children: [
          // Profile Header
          ProfileHeaderWidget(
            userName: userName,
            avatarUrl: avatarUrl,
            onEditPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Settings Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'EINSTELLUNGEN',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SwitchListTile(
            title: const Text('Benachrichtigungen'),
            subtitle: const Text('Push-Benachrichtigungen erhalten'),
            value: notificationsEnabled,
            onChanged: (value) {
              ref.read(notificationsProvider.notifier).update(value);
            },
            secondary: const Icon(Icons.notifications_outlined),
          ),

          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Dunkles Theme verwenden'),
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).toggle();
            },
            secondary: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode_outlined,
            ),
          ),

          const Divider(),

          // Collection Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'MEINE INHALTE',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.bookmark_outlined),
            title: const Text('Deine Sammlung'),
            subtitle: Text('$favoritesCount ${favoritesCount == 1 ? 'Element' : 'Elemente'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to Sammlung tab (index 3)
              final scaffoldContext = context;
              // Find the bottom nav screen and switch tab
              Navigator.of(scaffoldContext).popUntil((route) => route.isFirst);
              // This is a workaround - in production, use a proper navigation solution
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wechsle zum Sammlung-Tab'),
                ),
              );
            },
          ),

          const Divider(height: 32),

          // Danger Zone
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'GEFAHRENBEREICH',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.red,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _showDeleteDataDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Daten löschen'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Löscht alle deine lokalen Daten und setzt die App zurück.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

  Future<void> _showDeleteDataDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daten löschen?'),
        content: const Text(
          'Möchtest du wirklich alle deine Daten löschen? '
          'Diese Aktion kann nicht rückgängig gemacht werden.\n\n'
          'Folgende Daten werden gelöscht:\n'
          '• Dein Name und Einstellungen\n'
          '• Alle Favoriten\n'
          '• Bibelleseplan-Fortschritt\n'
          '• Dark Mode Einstellung',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteAllData(context, ref);
    }
  }

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
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
      ref.invalidate(notificationsProvider);
      ref.invalidate(themeModeProvider);

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate back to onboarding
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );

      // Show success message
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alle Daten wurden gelöscht'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog if open
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
