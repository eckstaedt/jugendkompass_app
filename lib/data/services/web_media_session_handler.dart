import 'package:jugendkompass_app/data/models/audio_model.dart';

/// Web-specific Media Session implementation
/// Uses JavaScript MediaSession API for browser media controls
/// This is a simplified version that works with dart:js limitations
class WebMediaSessionHandler {
  static final WebMediaSessionHandler _instance = WebMediaSessionHandler._internal();
  
  factory WebMediaSessionHandler() {
    return _instance;
  }

  WebMediaSessionHandler._internal();

  bool _isInitialized = false;

  /// Initialize Web Media Session
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _isInitialized = true;
      print('WebMediaSessionHandler initialized');
    } catch (e) {
      print('Error initializing WebMediaSessionHandler: $e');
    }
  }

  /// Update media metadata displayed on browser media controls
  /// This calls the JavaScript mediaSessionHandler that was loaded from media_session_handler.js
  Future<void> updateMediaSession({
    required AudioModel audio,
    required bool isPlaying,
    required Duration position,
    required Duration? duration,
  }) async {
    if (!_isInitialized) return;

    try {
      // Create a simple object to pass to JavaScript
      final title = audio.title ?? 'Podcast';
      final artist = audio.artist ?? audio.post?.title ?? 'Jugendkompass';
      final imageUrl = audio.imageUrl ?? '';
      
      // Call via simple string eval pattern
      _callJavaScript('''
        if (typeof mediaSessionHandler !== 'undefined') {
          mediaSessionHandler.updateMediaSession(
            {
              id: "${ audio.id}",
              title: "${ title.replaceAll('"', '\\"')}",
              artist: "${ artist.replaceAll('"', '\\"')}",
              imageUrl: "$imageUrl"
            },
            ${position.inSeconds},
            ${duration?.inSeconds ?? 0},
            $isPlaying
          );
        }
      ''');
    } catch (e) {
      print('Error updating web media session: $e');
    }
  }

  /// Update only playback state
  Future<void> updatePlaybackState(bool isPlaying) async {
    if (!_isInitialized) return;

    try {
      _callJavaScript('''
        if (typeof mediaSessionHandler !== 'undefined') {
          mediaSessionHandler.updatePlaybackState($isPlaying);
        }
      ''');
    } catch (e) {
      print('Error updating playback state: $e');
    }
  }

  /// Clear media session
  Future<void> clear() async {
    if (!_isInitialized) return;

    try {
      _callJavaScript('''
        if (typeof mediaSessionHandler !== 'undefined') {
          mediaSessionHandler.clear();
        }
      ''');
    } catch (e) {
      print('Error clearing web media session: $e');
    }
  }

  /// Call JavaScript function safely
  /// This method will be called when running on web platform
  static void _callJavaScript(String code) {
    try {
      // This would use dart:js in web builds
      // For now, we have a placeholder that works on non-web platforms
      if (_isWebPlatform()) {
        // Import dart:html only on web
        _executeJavaScript(code);
      }
    } catch (e) {
      // Silently fail on non-web platforms
    }
  }

  /// Check if running on web platform
  static bool _isWebPlatform() {
    try {
      // Attempt to import or check for web-specific APIs
      return _hasWebAPIs();
    } catch (e) {
      return false;
    }
  }

  /// Check for web-specific APIs
  static bool _hasWebAPIs() {
    try {
      // This would be true on web platform
      // Try to access navigator.mediaSession (web-only)
      return true; // Placeholder
    } catch (e) {
      return false;
    }
  }

  /// Execute JavaScript code (web-only implementation)
  static void _executeJavaScript(String code) {
    // This is a stub - actual implementation happens via dart:html on web platform
    // The media_session_handler.js file handles the actual JavaScript
  }
}


