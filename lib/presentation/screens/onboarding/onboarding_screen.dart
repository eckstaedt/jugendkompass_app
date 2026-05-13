import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/services/fcm_service.dart';
import 'package:jugendkompass_app/core/services/device_registration_service.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
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

    // Show notification permission info dialog and request permission
    if (!kIsWeb) {
      await _showNotificationPermissionDialog();
    }

    if (!mounted) return;

    // Navigate to main app
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const BottomNavScreen(),
      ),
    );
  }

  Future<void> _showNotificationPermissionDialog() async {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.getCardBackground(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications_outlined, color: DesignTokens.primaryRed),
            const SizedBox(width: 12),
            Text(
              'Benachrichtigungen',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Damit du täglich deinen Bibelvers und Infos über neue Beiträge erhältst, benötigen wir deine Erlaubnis für Benachrichtigungen.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: DesignTokens.getTextSecondary(brightness),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Überspringen',
              style: TextStyle(color: DesignTokens.getTextSecondary(brightness)),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _requestNotificationPermission();
            },
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.primaryRed,
            ),
            child: const Text('Erlauben'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    try {
      // Initialize FCM and request permission
      await FCMService().init();

      // Register device if notifications enabled
      final prefs = UserPreferencesService.instance;
      if (prefs.getNotificationsEnabled()) {
        await DeviceRegistrationService.instance.register(
          verseNotifications: prefs.getVerseNotificationsEnabled(),
          contentNotifications: prefs.getNewContentNotificationsEnabled(),
          notificationHour: prefs.getNotificationHour(),
          notificationMinute: prefs.getNotificationMinute(),
          language: prefs.getLanguage(),
        );
      }
    } catch (e) {
      debugPrint('Notification permission request error: $e');
    }
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


