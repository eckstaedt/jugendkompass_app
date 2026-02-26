import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/core/config/app_theme.dart';
import 'package:jugendkompass_app/presentation/navigation/bottom_nav_screen.dart';
import 'package:jugendkompass_app/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/domain/providers/theme_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Jugendkompass',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: FutureBuilder<bool>(
        future: Future.value(
          UserPreferencesService.instance.hasCompletedOnboarding(),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final hasCompletedOnboarding = snapshot.data ?? false;

          if (hasCompletedOnboarding) {
            return const BottomNavScreen();
          }

          return const OnboardingScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
