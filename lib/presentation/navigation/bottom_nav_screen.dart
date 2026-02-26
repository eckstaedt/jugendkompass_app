import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/presentation/screens/home/home_screen.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/podcast_screen.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/kiosk_screen.dart';
import 'package:jugendkompass_app/presentation/screens/search/search_screen.dart';
import 'package:jugendkompass_app/presentation/screens/profile/profile_screen.dart';
import 'package:jugendkompass_app/presentation/screens/podcast/widgets/mini_player_bar.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';

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
      body: _screens[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini Player Bar (shown when audio is playing)
          if (currentAudio != null) MiniPlayerBar(audio: currentAudio),

          // Navigation Bar with custom styling
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                      icon: Icons.auto_stories_outlined,
                      selectedIcon: Icons.auto_stories,
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
    const primaryColor = Color(0xFF8B3A3A);
    const textGray = Color(0xFF6B7280);

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? primaryColor : textGray,
                size: 26,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
