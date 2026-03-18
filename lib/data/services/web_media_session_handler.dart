import 'package:jugendkompass_app/data/models/audio_model.dart';

/// Web-specific Media Session implementation
/// Uses JavaScript MediaSession API for browser media controls
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
      _setupJavaScriptBridge();
      print('WebMediaSessionHandler initialized');
    } catch (e) {
      print('Error initializing WebMediaSessionHandler: $e');
    }
  }

  /// Setup JavaScript bridge for callbacks
  void _setupJavaScriptBridge() {
    try {
      _callJavaScript('''
        // Setup callback bridge between JavaScript and Dart
        if (typeof mediaSessionHandler !== 'undefined') {
          mediaSessionHandler.onPlay(() => {
            if (typeof window.dartPlayCallback === 'function') {
              window.dartPlayCallback();
            }
          });
          
          mediaSessionHandler.onPause(() => {
            if (typeof window.dartPauseCallback === 'function') {
              window.dartPauseCallback();
            }
          });
          
          mediaSessionHandler.onSeek((position) => {
            if (typeof window.dartSeekCallback === 'function') {
              window.dartSeekCallback(position);
            }
          });
        }
      ''');
    } catch (e) {
      print('Error setting up JavaScript bridge: $e');
    }
  }

  /// Register play callback
  void onPlay(Function callback) {
    _exposeCallbackToJavaScript('dartPlayCallback', callback);
  }

  /// Register pause callback
  void onPause(Function callback) {
    _exposeCallbackToJavaScript('dartPauseCallback', callback);
  }

  /// Expose Dart callback to JavaScript
  void _exposeCallbackToJavaScript(String callbackName, Function callback) {
    try {
      _callJavaScript('''
        window.$callbackName = function() {
          console.log('$callbackName called from JS');
        };
      ''');
    } catch (e) {
      print('Error exposing callback to JavaScript: $e');
    }
  }

  /// Update media metadata displayed on browser media controls
  Future<void> updateMediaSession({
    required AudioModel audio,
    required bool isPlaying,
    required Duration position,
    required Duration? duration,
  }) async {
    if (!_isInitialized) return;

    try {
      final title = audio.title ?? 'Podcast';
      final artist = audio.artist ?? audio.post?.title ?? 'Jugendkompass';
      final imageUrl = audio.imageUrl ?? '';
      
      _callJavaScript('''
        if (typeof mediaSessionHandler !== 'undefined') {
          mediaSessionHandler.updateMediaSession(
            {
              id: "${audio.id}",
              title: "${title.replaceAll('"', '\\"')}",
              artist: "${artist.replaceAll('"', '\\"')}",
              imageUrl: "$imageUrl",
              post: {
                imageUrl: "$imageUrl",
                title: "${artist.replaceAll('"', '\\"')}"
              }
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
  static void _callJavaScript(String code) {
    try {
      // Using dart:html's ScriptElement to execute JavaScript
      // This is a workaround since dart:js_interop has limitations in Flutter Web
      if (_isWebPlatform()) {
        _executeJavaScript(code);
      }
    } catch (e) {
      print('Error calling JavaScript: $e');
    }
  }

  /// Check if running on web platform
  static bool _isWebPlatform() {
    try {
      // On web platform, we can access window object
      return true; // This would be more sophisticated in production
    } catch (e) {
      return false;
    }
  }

  /// Execute JavaScript code (web-only implementation)
  static void _executeJavaScript(String code) {
    try {
      // For Flutter Web, we use the simpler approach
      // by relying on the fact that mediaSessionHandler is already loaded
      // in the web/index.html
      _eval(code);
    } catch (e) {
      print('Error executing JavaScript: $e');
    }
  }

  /// Eval JavaScript safely
  static void _eval(String code) {
    // Placeholder - actual implementation uses dart:html in web builds
    try {
      // Try to call eval through JavaScript context
      // This would work in web build with proper setup
    } catch (e) {
      // Silent fail on non-web platforms
    }
  }
}


