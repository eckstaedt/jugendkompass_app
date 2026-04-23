import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/theme_provider.dart';
import '../../../data/services/user_preferences_service.dart';
import '../../navigation/bottom_nav_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    // Ensure the global navbar is hidden while onboarding is shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navBarVisibleProvider.notifier).state = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    setState(() {
      _isValid = value.trim().length >= 2;
    });
  }

  Future<void> _onSubmit() async {
    if (!_isValid) return;

    final name = _nameController.text.trim();

    // Save name to local storage
    await UserPreferencesService.instance.setUserName(name);
    await UserPreferencesService.instance.setOnboardingComplete();

    if (!mounted) return;

    // Show theme picker dialog before entering app
    await _showThemePickerDialog();
  }

  Future<void> _showThemePickerDialog() async {
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
                    'Wie magst du die App?',
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

    // Apply chosen theme
    if (chosen != null) {
      await ref.read(themeModeProvider.notifier).setThemeMode(chosen);
    }

    // Navigate to main app
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const BottomNavScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.paddingHorizontal),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: DesignTokens.getCardBackground(brightness),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
                    boxShadow: [DesignTokens.shadowLargeCard],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.primaryRed.withOpacity(0.4),
                              blurRadius: 35,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/logo_new.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingMedium),

                      // Headline
                      Text(
                        'Der Jugendkompass',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          textStyle: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: DesignTokens.getTextPrimary(brightness),
                              ) ??
                              TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: DesignTokens.getTextPrimary(brightness),
                              ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Subtitle
                      Text(
                        'Dein täglicher Begleiter für dein Glaubensleben.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          textStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: DesignTokens.getTextSecondary(brightness),
                              ) ??
                              TextStyle(color: DesignTokens.getTextSecondary(brightness)),
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingLarge),

                      // Name Input Field
                      SizedBox(
                        height: 50,
                        child: TextField(
                          controller: _nameController,
                          onChanged: _onNameChanged,
                          onSubmitted: (_) => _onSubmit(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Wie heißt du?',
                            hintStyle: GoogleFonts.inter(
                              textStyle: TextStyle(
                                color: DesignTokens.getTextSecondary(brightness),
                                fontSize: 16,
                              ),
                            ),
                            filled: true,
                            fillColor: brightness == Brightness.dark
                                ? DesignTokens.darkCardBackground
                                : DesignTokens.inputBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusInputFields),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingMedium),

                      // Submit Button with shadow
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                          boxShadow: [DesignTokens.shadowButton],
                        ),
                        child: FilledButton(
                          onPressed: _isValid ? _onSubmit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: DesignTokens.primaryRed,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                            ),
                            disabledBackgroundColor: DesignTokens.primaryRed.withOpacity(0.5),
                            disabledForegroundColor: Colors.white.withOpacity(0.7),
                          ),
                          child: Text(
                            'Los geht\'s 🚀',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
