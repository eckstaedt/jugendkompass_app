// Stub implementation for non-web platforms.
// All functions are no-ops.

void webInit() {}

void webUpdateMediaSession({
  required String id,
  required String title,
  required String artist,
  required String imageUrl,
  required int positionSeconds,
  required int durationSeconds,
  required bool isPlaying,
}) {}

void webUpdatePlaybackState(bool isPlaying) {}

void webClear() {}
