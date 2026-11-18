import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:jugendkompass_app/data/models/video_model.dart';

/// Cache provider for video durations to avoid re-fetching from network
final videoDurationCacheProvider = StateNotifierProvider<VideoDurationCache, Map<String, int>>((ref) {
  return VideoDurationCache({});
});

class VideoDurationCache extends StateNotifier<Map<String, int>> {
  VideoDurationCache(super.state);

  Future<int> getDuration(VideoModel video) async {
    // Return cached duration if available
    if (state.containsKey(video.id)) {
      return state[video.id]!;
    }

    // If video model already has duration, cache and return it
    if (video.duration != null && video.duration! > 0) {
      state = {...state, video.id: video.duration!};
      return video.duration!;
    }

    // Otherwise, load from video file
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(video.url),
      );
      await controller.initialize();
      final duration = controller.value.duration.inSeconds;
      await controller.dispose();

      // Cache the duration
      state = {...state, video.id: duration};
      return duration;
    } catch (e) {
      // If loading fails, return 0
      return 0;
    }
  }
}
