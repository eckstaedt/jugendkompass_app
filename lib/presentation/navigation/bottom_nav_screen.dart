import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/presentation/screens/home/home_screen.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/podcast_screen.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/kiosk_screen.dart';
import 'package:jugendkompass_app/presentation/screens/video/video_screen.dart';
import 'package:jugendkompass_app/presentation/screens/profile/profile_screen.dart';
import 'package:jugendkompass_app/domain/providers/bottom_nav_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

class BottomNavScreen extends ConsumerWidget {
  const BottomNavScreen({super.key});

  // Navbar height: 60px bar + 4px top margin + 16px bottom margin = 80px
  // We also add the bottom safe-area inset at runtime.
  static const double _navBarHeight = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    // Tell the persistent mini player how far above the bottom to sit.
    final safeBottom = MediaQuery.of(context).padding.bottom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miniPlayerBottomOffsetProvider.notifier).state =
          _navBarHeight + safeBottom;
    });

    final screens = [
      HomeScreen(),
      KioskScreen(),
      PodcastScreen(),
      VideoScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: screens[selectedIndex],
      // extendBody lets screen content scroll behind the floating navbar.
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusNavBar),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DesignTokens.glassBlurSigma,
              sigmaY: DesignTokens.glassBlurSigma,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.glassBackground(0.14),
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusNavBar),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [DesignTokens.shadowGlass],
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        context: context,
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home,
                        label: 'Home',
                        index: 0,
                        isSelected: selectedIndex == 0,
                        onTap: () => ref
                            .read(bottomNavIndexProvider.notifier)
                            .setIndex(0),
                      ),
                      _buildNavItem(
                        context: context,
                        icon: Icons.explore_outlined,
                        selectedIcon: Icons.explore,
                        label: 'Kiosk',
                        index: 1,
                        isSelected: selectedIndex == 1,
                        onTap: () => ref
                            .read(bottomNavIndexProvider.notifier)
                            .setIndex(1),
                      ),
                      _buildNavItem(
                        context: context,
                        icon: Icons.mic_outlined,
                        selectedIcon: Icons.mic,
                        label: 'Podcast',
                        index: 2,
                        isSelected: selectedIndex == 2,
                        onTap: () => ref
                            .read(bottomNavIndexProvider.notifier)
                            .setIndex(2),
                      ),
                      _buildNavItem(
                        context: context,
                        icon: Icons.video_library_outlined,
                        selectedIcon: Icons.video_library,
                        label: 'Videos',
                        index: 3,
                        isSelected: selectedIndex == 3,
                        onTap: () => ref
                            .read(bottomNavIndexProvider.notifier)
                            .setIndex(3),
                      ),
                      _buildNavItem(
                        context: context,
                        icon: Icons.menu,
                        selectedIcon: Icons.menu,
                        label: 'Menü',
                        index: 4,
                        isSelected: selectedIndex == 4,
                        onTap: () => ref
                            .read(bottomNavIndexProvider.notifier)
                            .setIndex(4),
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

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: DesignTokens.primaryRed.withOpacity(0.1),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? DesignTokens.primaryRed
                      : DesignTokens.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 5 : 0,
                  height: isSelected ? 5 : 0,
                  decoration: const BoxDecoration(
                    color: DesignTokens.primaryRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
