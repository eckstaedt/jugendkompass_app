// Platform-safe Web Media Session handler.
// On web: delegates to the mediaSessionHandler JS object in web/index.html.
// On mobile/desktop: all methods are no-ops.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jugendkompass_app/data/models/audio_model.dart';

// Conditional import: only loaded when compiling for web.
import 'web_media_session_handler_web.dart'
    if (dart.library.io) 'web_media_session_handler_stub.dart' as impl;

/// Public facade — safe to instantiate on every platform.
class WebMediaSessionHandler {
  static final WebMediaSessionHandler _instance =
      WebMediaSessionHandler._internal();

  factory WebMediaSessionHandler() => _instance;

  WebMediaSessionHandler._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb) impl.webInit();
  }

  Future<void> updateMediaSession({
    required AudioModel audio,
    required bool isPlaying,
    required Duration position,
    required Duration? duration,
  }) async {
    if (!kIsWeb || !_initialized) return;
    impl.webUpdateMediaSession(
      id: audio.id,
      title: audio.title ?? 'Podcast',
      artist: audio.artist ?? audio.post?.title ?? 'Jugendkompass',
      imageUrl: audio.imageUrl ?? '',
      positionSeconds: position.inSeconds,
      durationSeconds: duration?.inSeconds ?? 0,
      isPlaying: isPlaying,
    );
  }

  Future<void> updatePlaybackState(bool isPlaying) async {
    if (!kIsWeb || !_initialized) return;
    impl.webUpdatePlaybackState(isPlaying);
  }

  Future<void> clear() async {
    if (!kIsWeb || !_initialized) return;
    impl.webClear();
  }
}
