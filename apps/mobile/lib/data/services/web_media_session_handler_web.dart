// Web implementation using dart:js_interop (replaces deprecated dart:js / dart:html).
// Only compiled on web targets.

import 'dart:js_interop';

@JS('eval')
external void _jsEval(String code);

void webInit() {
  try {
    _jsEval('''
      if (typeof window.dartAudioCallbacks === "undefined") {
        window.dartAudioCallbacks = {};
      }
    ''');
  } catch (_) {}
}

void webUpdateMediaSession({
  required String id,
  required String title,
  required String artist,
  required String imageUrl,
  required int positionSeconds,
  required int durationSeconds,
  required bool isPlaying,
}) {
  try {
    final safeTitle = title.replaceAll('"', '\\"');
    final safeArtist = artist.replaceAll('"', '\\"');
    final safeImage = imageUrl.replaceAll('"', '\\"');
    _jsEval('''
      (function() {
        if (typeof mediaSessionHandler !== "undefined") {
          mediaSessionHandler.updateMediaSession(
            { id: "$id", title: "$safeTitle", artist: "$safeArtist",
              imageUrl: "$safeImage", post: { imageUrl: "$safeImage", title: "$safeArtist" } },
            $positionSeconds, $durationSeconds, $isPlaying
          );
        } else if ("mediaSession" in navigator) {
          navigator.mediaSession.metadata = new MediaMetadata({
            title: "$safeTitle", artist: "$safeArtist",
            artwork: [{ src: "$safeImage", sizes: "512x512", type: "image/jpeg" }]
          });
          navigator.mediaSession.playbackState = $isPlaying ? "playing" : "paused";
        }
      })();
    ''');
  } catch (_) {}
}

void webUpdatePlaybackState(bool isPlaying) {
  try {
    _jsEval('''
      if ("mediaSession" in navigator) {
        navigator.mediaSession.playbackState = ${isPlaying ? '"playing"' : '"paused"'};
      }
    ''');
  } catch (_) {}
}

void webClear() {
  try {
    _jsEval('''
      if ("mediaSession" in navigator) {
        navigator.mediaSession.metadata = null;
        navigator.mediaSession.playbackState = "none";
      }
    ''');
  } catch (_) {}
}
