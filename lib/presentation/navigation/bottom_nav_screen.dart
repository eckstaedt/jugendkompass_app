import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/presentation/screens/home/home_screen.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/podcast_screen.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/kiosk_screen.dart';
import 'package:jugendkompass_app/presentation/screens/search/search_screen.dart';
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
    SearchScreen(),
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

          // Navigation Bar with custom rounded styling
          Container(
            color: Colors.transparent,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [DesignTokens.shadowSubtle],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                          icon: Icons.compass_calibration_outlined,
                          selectedIcon: Icons.compass_calibration,
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
                          icon: Icons.search_outlined,
                          selectedIcon: Icons.search,
                          label: 'Suche',
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? DesignTokens.primaryRed : DesignTokens.textSecondary,
                size: 30,
              ),
              const SizedBox(height: 6),
              // Dot indicator for selected item
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 6 : 0,
                height: isSelected ? 6 : 0,
                decoration: const BoxDecoration(
                  color: DesignTokens.primaryRed,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
