import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_player_provider.dart';

/// Provider for selected podcast category filter
final selectedPodcastCategoryProvider = StateProvider<String?>((ref) => null);

/// Provider for filtered audio list based on selected category
final filteredPodcastListProvider = Provider((ref) {
  final audioListAsync = ref.watch(audioListProvider);
  final selectedCategory = ref.watch(selectedPodcastCategoryProvider);

  return audioListAsync.when(
    data: (audioList) {
      if (selectedCategory == null) {
        return audioList;
      }

      // Filter by category name
      return audioList.where((audio) {
        // This assumes you have category information in the audio model
        // Adjust based on your actual data structure
        return audio.categoryId == selectedCategory;
      }).toList();
    },
    loading: () => <dynamic>[],
    error: (_, _) => <dynamic>[],
  );
});
