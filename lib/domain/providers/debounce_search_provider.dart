import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debounce provider for search queries to reduce API calls
final debouncedSearchProvider = StateNotifierProvider<DebouncedSearchNotifier, String>((ref) {
  return DebouncedSearchNotifier();
});

class DebouncedSearchNotifier extends StateNotifier<String> {
  Timer? _debounceTimer;
  static const Duration debounceDelay = Duration(milliseconds: 300);

  DebouncedSearchNotifier() : super('');

  void setSearchQuery(String query) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(debounceDelay, () {
      state = query;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
