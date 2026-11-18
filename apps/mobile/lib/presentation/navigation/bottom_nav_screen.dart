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
      // Always start on home screen
      ref.read(bottomNavIndexProvider.notifier).setIndex(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    // Tell the persistent mini player how far above the bottom to sit.
    final safeBottom = MediaQuery.of(context).padding.bottom;
    // Mirror the navbar's own bottom margin: `safeBottom > 0 ? safeBottom : 16`
    final navBottomMargin = (safeBottom > 0 ? safeBottom : 16.0) + 3;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miniPlayerBottomOffsetProvider.notifier).state =
          BottomNavScreen.navBarHeight + navBottomMargin;
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

