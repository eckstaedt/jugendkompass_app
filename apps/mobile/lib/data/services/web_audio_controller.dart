// Platform-safe web audio controller.
// On web it delegates to JavaScript via package:web / dart:js_interop.
// On mobile/desktop it does nothing.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jugendkompass_app/data/services/audio_service.dart';

/// Registers Dart audio callbacks with the page's JavaScript bridge so that
/// browser media-session buttons (play/pause etc.) work on web.
///
/// Safe to call on any platform — it is a no-op on non-web targets.
class WebAudioController {
  static final WebAudioController _instance = WebAudioController._internal();

  factory WebAudioController() => _instance;

  WebAudioController._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || !kIsWeb) return;
    _initialized = true;
    // On web the media_session_handler.js loaded in web/index.html exposes
    // window.dartAudioAPI. We can't call dart:html here because this file
    // must compile for all platforms.  The actual JS wiring is done inside
    // web_media_session_handler.dart which is web-only.
  }

  // ── Static helpers called by JS (web only, called via WebMediaSessionHandler)

  static void play() {
    if (!kIsWeb) return;
    try { AudioService.instance.resume(); } catch (_) {}
  }

  static void pause() {
    if (!kIsWeb) return;
    try { AudioService.instance.pause(); } catch (_) {}
  }

  static void skipForward(int seconds) {
    if (!kIsWeb) return;
    try { AudioService.instance.skipForward(seconds); } catch (_) {}
  }

  static void skipBackward(int seconds) {
    if (!kIsWeb) return;
    try { AudioService.instance.skipBackward(seconds); } catch (_) {}
  }

  static void seek(int seconds) {
    if (!kIsWeb) return;
    try { AudioService.instance.seek(Duration(seconds: seconds)); } catch (_) {}
  }
}
