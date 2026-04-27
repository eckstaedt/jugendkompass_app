import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/domain/providers/theme_provider.dart';
import 'package:jugendkompass_app/presentation/screens/home/home_screen.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/podcast_screen.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/kiosk_screen.dart';
import 'package:jugendkompass_app/presentation/screens/video/video_screen.dart';
import 'package:jugendkompass_app/presentation/screens/profile/profile_screen.dart';
import 'package:jugendkompass_app/domain/providers/bottom_nav_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';

class BottomNavScreen extends ConsumerStatefulWidget {
  const BottomNavScreen({super.key});

  // Navbar height used by the global overlay in app.dart.
  // 60 (bar) + 4 (top margin) = 64, safe area bottom is added dynamically.
  static const double navBarHeight = 64;

  @override
  ConsumerState<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends ConsumerState<BottomNavScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowThemeDialog();
    });
  }

  Future<void> _maybeShowThemeDialog() async {
    if (!mounted) return;
    final prefs = UserPreferencesService.instance;
    if (prefs.getHasChosenTheme()) return;

    final brightness = Theme.of(context).brightness;
    final cardBg = DesignTokens.getCardBackground(brightness);
    final textPrimary = DesignTokens.getTextPrimary(brightness);
    final textSecondary = DesignTokens.getTextSecondary(brightness);

    ThemeMode? chosen = await showDialog<ThemeMode>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        ThemeMode selected = ThemeMode.system;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Erscheinungsbild wählen',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Du kannst das jederzeit in den Einstellungen ändern.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ThemeOption(
                        icon: Icons.wb_sunny_rounded,
                        label: 'Hell',
                        selected: selected == ThemeMode.light,
                        onTap: () => setDialogState(() => selected = ThemeMode.light),
                      ),
                      _ThemeOption(
                        icon: Icons.dark_mode_rounded,
                        label: 'Dunkel',
                        selected: selected == ThemeMode.dark,
                        onTap: () => setDialogState(() => selected = ThemeMode.dark),
                      ),
                      _ThemeOption(
                        icon: Icons.phone_iphone_rounded,
                        label: 'System',
                        selected: selected == ThemeMode.system,
                        onTap: () => setDialogState(() => selected = ThemeMode.system),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(selected),
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignTokens.primaryRed,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                        ),
                      ),
                      child: const Text(
                        'Fertig',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (chosen != null) {
      await ref.read(themeModeProvider.notifier).setThemeMode(chosen);
    }
    await prefs.setHasChosenTheme();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    // Tell the persistent mini player how far above the bottom to sit.
    final safeBottom = MediaQuery.of(context).padding.bottom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miniPlayerBottomOffsetProvider.notifier).state =
          BottomNavScreen.navBarHeight + safeBottom;
      // Show the global navbar overlay.
      ref.read(navBarVisibleProvider.notifier).state = true;
    });

    final screens = [
      HomeScreen(),
      KioskScreen(),
      PodcastScreen(),
      VideoScreen(),
      ProfileScreen(),
    ];

    // extendBody lets content scroll behind the floating navbar overlay.
    return Scaffold(
      extendBody: true,
      body: screens[selectedIndex],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final primaryRed = DesignTokens.primaryRed;
    final bg = selected
        ? primaryRed.withOpacity(0.12)
        : DesignTokens.getGlassBackground(brightness, 0.10);
    final borderColor = selected ? primaryRed : Colors.transparent;
    final iconColor = selected ? primaryRed : DesignTokens.getTextSecondary(brightness);
    final labelColor = selected ? primaryRed : DesignTokens.getTextSecondary(brightness);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
