import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
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
                    color: DesignTokens.cardBackground,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLargeCards),
                    boxShadow: [DesignTokens.shadowLargeCard],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo container
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: DesignTokens.primaryRed,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.primaryRed.withOpacity(0.4),
                              blurRadius: 35,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.explore,
                            color: Colors.white,
                            size: 40,
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
                                color: DesignTokens.textPrimary,
                              ) ??
                              const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111111),
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
                                color: DesignTokens.textSecondary,
                              ) ??
                              const TextStyle(color: Color(0xFF6F7479)),
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
                              textStyle: const TextStyle(
                                color: Color(0xFF6F7479),
                                fontSize: 16,
                              ),
                            ),
                            filled: true,
                            fillColor: DesignTokens.inputBackground,
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
                          child: const Text(
                            'Los geht\'s 🚀',
                            style: TextStyle(
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
