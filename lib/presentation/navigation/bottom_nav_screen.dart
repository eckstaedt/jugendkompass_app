import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/presentation/screens/home/home_screen.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/podcast_screen.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/kiosk_screen.dart';
import 'package:jugendkompass_app/presentation/screens/video/video_screen.dart';
import 'package:jugendkompass_app/presentation/screens/profile/profile_screen.dart';
import 'package:jugendkompass_app/domain/providers/bottom_nav_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';

class BottomNavScreen extends ConsumerWidget {
  const BottomNavScreen({super.key});

  // Navbar height used by the global overlay in app.dart.
  static const double navBarHeight = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    // Tell the persistent mini player how far above the bottom to sit.
    final safeBottom = MediaQuery.of(context).padding.bottom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miniPlayerBottomOffsetProvider.notifier).state =
          navBarHeight + safeBottom;
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
