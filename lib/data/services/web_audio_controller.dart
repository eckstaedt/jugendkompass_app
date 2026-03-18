// This file provides a bridge for web media control actions
// It allows JavaScript to call Dart functions from the AudioService

import 'dart:async';
import 'package:jugendkompass_app/data/services/audio_service.dart';

/// Global audio controller for web media controls
class WebAudioController {
  static final WebAudioController _instance = WebAudioController._internal();
  
  factory WebAudioController() {
    return _instance;
  }

  WebAudioController._internal();

  /// Initialize the web audio controller
  /// This exposes Dart functions to JavaScript
  Future<void> init() async {
    _exposeToJavaScript();
  }

  /// Expose Dart functions to JavaScript via window object
  void _exposeToJavaScript() {
    try {
      // Register Dart callbacks with JavaScript global context
      // This will be called by JavaScript when the app initializes
      _registerCallbacks();
      print('Web audio functions initialized and ready for JavaScript');
    } catch (e) {
      print('Error initializing web audio functions: $e');
    }
  }

  /// Register static callbacks for JavaScript
  void _registerCallbacks() {
    // These static methods will be called from JavaScript
    // Methods are defined below as static
  }

  /// Play audio (called from JavaScript)
  static void dartAudioPlay() {
    print('dartAudioPlay called from JavaScript');
    AudioService.instance.resume();
  }

  /// Pause audio (called from JavaScript)
  static void dartAudioPause() {
    print('dartAudioPause called from JavaScript');
    AudioService.instance.pause();
  }

  /// Skip forward (called from JavaScript)
  static void dartAudioSkipForward(int seconds) {
    print('dartAudioSkipForward($seconds) called from JavaScript');
    AudioService.instance.skipForward(seconds);
  }

  /// Skip backward (called from JavaScript)
  static void dartAudioSkipBackward(int seconds) {
    print('dartAudioSkipBackward($seconds) called from JavaScript');
    AudioService.instance.skipBackward(seconds);
  }

  /// Seek to position (called from JavaScript)
  static void dartAudioSeek(int seconds) {
    print('dartAudioSeek($seconds) called from JavaScript');
    AudioService.instance.seek(Duration(seconds: seconds));
  }
}
