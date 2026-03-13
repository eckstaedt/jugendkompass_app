import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/presentation/screens/home/home_screen.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/podcast_screen.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/kiosk_screen.dart';
import 'package:jugendkompass_app/presentation/screens/video/video_screen.dart';
import 'package:jugendkompass_app/presentation/screens/profile/profile_screen.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/widgets/mini_player_bar.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

class BottomNavScreen extends ConsumerStatefulWidget {
  const BottomNavScreen({super.key});

  @override
  ConsumerState<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends ConsumerState<BottomNavScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    KioskScreen(),
    PodcastScreen(),
    VideoScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentAudio = ref.watch(currentAudioProvider);

    return Scaffold(
      backgroundColor: DesignTokens.appBackground,
      body: _screens[_selectedIndex],
      extendBody: true, // Extend body behind bottom nav
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini Player Bar (shown when audio is playing)
          if (currentAudio != null) MiniPlayerBar(audio: currentAudio),

          // Navigation Bar with iOS 26 liquid glass design
          // Flowing, rounded, blurry navbar
          Container(
            // slightly reduce bottom margin to eliminate a 4px overflow
            // that was occurring on some devices. The navbar itself remains
            // 60px tall and the icons keep their existing centering – we
            // merely trim the external spacing by the exact overflow amount.
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            // limit total height so icons sit perfectly centered
            height: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusNavBar),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: DesignTokens.glassBlurSigma,
                    sigmaY: DesignTokens.glassBlurSigma),
                child: Container(
                  decoration: BoxDecoration(
                    color: DesignTokens.glassBackground(0.14),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusNavBar),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                            context: context,
                            icon: Icons.home_outlined,
                            selectedIcon: Icons.home,
                            label: 'Home',
                            index: 0,
                          ),
                          _buildNavItem(
                            context: context,
                            icon: Icons.explore_outlined,
                            selectedIcon: Icons.explore,
                            label: 'Kiosk',
                            index: 1,
                          ),
                          _buildNavItem(
                            context: context,
                            icon: Icons.mic_outlined,
                            selectedIcon: Icons.mic,
                            label: 'Podcast',
                            index: 2,
                          ),
                          _buildNavItem(
                            context: context,
                            icon: Icons.video_library_outlined,
                            selectedIcon: Icons.video_library,
                            label: 'Videos',
                            index: 3,
                          ),
                          _buildNavItem(
                            context: context,
                            icon: Icons.menu,
                            selectedIcon: Icons.menu,
                            label: 'Menü',
                            index: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
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
                  color: isSelected ? DesignTokens.primaryRed : DesignTokens.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: 4),
                // Dot indicator for selected item
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
