import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing the selected bottom navigation index
final bottomNavIndexProvider = StateNotifierProvider<BottomNavIndexNotifier, int>(
  (ref) => BottomNavIndexNotifier(),
);

class BottomNavIndexNotifier extends StateNotifier<int> {
  BottomNavIndexNotifier() : super(0);

  void setIndex(int index) {
    state = index;
  }
}
