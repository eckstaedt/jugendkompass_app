// This file provides a bridge for web media control actions
// It allows JavaScript to call Dart functions from the AudioService

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
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
    _registerWithJavaScript();
  }

  /// Register Dart functions with JavaScript using the callback pattern
  void _registerWithJavaScript() {
    try {
      // Step 1: Create placeholders for the callbacks on the window object
      _createJavaScriptPlaceholders();
      
      // Step 2: Register our Dart static methods as callbacks via dynamic window
      _injectDartFunctionWrappers();
      
      print('✓ Web audio controller registered with JavaScript');
    } catch (e) {
      print('Error registering web audio controller: $e');
    }
  }

  /// Create placeholder functions on the window object for JavaScript to call
  void _createJavaScriptPlaceholders() {
    try {
      final scriptContent = '''
        // Create the dartAudioAPI object if it doesn't exist
        if (typeof window.dartAudioAPI === 'undefined') {
          window.dartAudioAPI = {
            play: null,
            pause: null,
            skipForward: null,
            skipBackward: null,
            seek: null
          };
          console.log('[Dart Bridge] Placeholder object created for dartAudioAPI');
        }
      ''';
      
      // Execute the script to create the placeholders
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..text = scriptContent;
      html.document.head!.append(script);
      
      print('✓ JavaScript placeholders created');
    } catch (e) {
      print('Error creating JavaScript placeholders: $e');
    }
  }

  /// Inject wrapper functions that call our static Dart methods
  /// This works around Dart's type system limitations
  void _injectDartFunctionWrappers() {
    try {
      final scriptContent = '''
        // Override the placeholder functions with actual wrappers
        // These wrappers will be called by JavaScript
        if (typeof window.dartAudioAPI !== 'undefined') {
          // Store references to the callback functions
          window.dartAudioAPI.play = function() {
            console.log('[JS->Dart] dartAudioAPI.play() called');
            // The actual Dart function will be injected here
            if (window.dartAudioCallbacks && window.dartAudioCallbacks.play) {
              window.dartAudioCallbacks.play();
            } else {
              console.warn('[JS->Dart] dartAudioCallbacks.play not yet available');
            }
          };
          
          window.dartAudioAPI.pause = function() {
            console.log('[JS->Dart] dartAudioAPI.pause() called');
            if (window.dartAudioCallbacks && window.dartAudioCallbacks.pause) {
              window.dartAudioCallbacks.pause();
            } else {
              console.warn('[JS->Dart] dartAudioCallbacks.pause not yet available');
            }
          };
          
          window.dartAudioAPI.skipForward = function(seconds) {
            console.log('[JS->Dart] dartAudioAPI.skipForward(' + seconds + ') called');
            if (window.dartAudioCallbacks && window.dartAudioCallbacks.skipForward) {
              window.dartAudioCallbacks.skipForward(seconds);
            } else {
              console.warn('[JS->Dart] dartAudioCallbacks.skipForward not yet available');
            }
          };
          
          window.dartAudioAPI.skipBackward = function(seconds) {
            console.log('[JS->Dart] dartAudioAPI.skipBackward(' + seconds + ') called');
            if (window.dartAudioCallbacks && window.dartAudioCallbacks.skipBackward) {
              window.dartAudioCallbacks.skipBackward(seconds);
            } else {
              console.warn('[JS->Dart] dartAudioCallbacks.skipBackward not yet available');
            }
          };
          
          window.dartAudioAPI.seek = function(seconds) {
            console.log('[JS->Dart] dartAudioAPI.seek(' + seconds + ') called');
            if (window.dartAudioCallbacks && window.dartAudioCallbacks.seek) {
              window.dartAudioCallbacks.seek(seconds);
            } else {
              console.warn('[JS->Dart] dartAudioCallbacks.seek not yet available');
            }
          };
          
          console.log('[Dart Bridge] Function wrappers injected into dartAudioAPI');
        }
      ''';
      
      // Execute the wrapper injection script
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..text = scriptContent;
      html.document.head!.append(script);
      
      // Now register the actual Dart callbacks
      _registerDartCallbacks();
      
      print('✓ Dart function wrappers injected');
    } catch (e) {
      print('Error injecting Dart function wrappers: $e');
    }
  }

  /// Register the actual Dart functions as callbacks that JavaScript can invoke
  void _registerDartCallbacks() {
    try {
      final scriptContent = '''
        // Create the callback object that will hold references to Dart functions
        if (typeof window.dartAudioCallbacks === 'undefined') {
          window.dartAudioCallbacks = {};
        }
        
        // These will be overwritten by the Dart code below
        window.dartAudioCallbacks.play = null;
        window.dartAudioCallbacks.pause = null;
        window.dartAudioCallbacks.skipForward = null;
        window.dartAudioCallbacks.skipBackward = null;
        window.dartAudioCallbacks.seek = null;
        
        console.log('[Dart Bridge] Callback object created');
      ''';
      
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..text = scriptContent;
      html.document.head!.append(script);
      
      // Use the js package to access the window object dynamically
      // This allows us to set properties on the window object
      try {
        final window = js.context as dynamic;
        
        // Create the dartAudioCallbacks object if it doesn't exist
        if (window['dartAudioCallbacks'] == null) {
          window['dartAudioCallbacks'] = <String, dynamic>{};
        }
        
        // Register each callback function
        window['dartAudioCallbacks']['play'] = () {
          print('[Dart] play() called from JavaScript');
          play();
        };
        
        window['dartAudioCallbacks']['pause'] = () {
          print('[Dart] pause() called from JavaScript');
          pause();
        };
        
        window['dartAudioCallbacks']['skipForward'] = (dynamic seconds) {
          print('[Dart] skipForward($seconds) called from JavaScript');
          skipForward(seconds is int ? seconds : int.parse(seconds.toString()));
        };
        
        window['dartAudioCallbacks']['skipBackward'] = (dynamic seconds) {
          print('[Dart] skipBackward($seconds) called from JavaScript');
          skipBackward(seconds is int ? seconds : int.parse(seconds.toString()));
        };
        
        window['dartAudioCallbacks']['seek'] = (dynamic seconds) {
          print('[Dart] seek($seconds) called from JavaScript');
          seek(seconds is int ? seconds : int.parse(seconds.toString()));
        };
        
        print('✓ Dart callbacks registered with JavaScript');
      } catch (e) {
        print('Error registering Dart callbacks: $e');
      }
    } catch (e) {
      print('Error in _registerDartCallbacks: $e');
    }
  }

  /// Play audio (called from JavaScript via callback)
  static void play() {
    print('[Dart] play() called');
    try {
      AudioService.instance.resume();
    } catch (e) {
      print('Error in play(): $e');
    }
  }

  /// Pause audio (called from JavaScript via callback)
  static void pause() {
    print('[Dart] pause() called');
    try {
      AudioService.instance.pause();
    } catch (e) {
      print('Error in pause(): $e');
    }
  }

  /// Skip forward (called from JavaScript via callback)
  static void skipForward(int seconds) {
    print('[Dart] skipForward($seconds) called');
    try {
      AudioService.instance.skipForward(seconds);
    } catch (e) {
      print('Error in skipForward(): $e');
    }
  }

  /// Skip backward (called from JavaScript via callback)
  static void skipBackward(int seconds) {
    print('[Dart] skipBackward($seconds) called');
    try {
      AudioService.instance.skipBackward(seconds);
    } catch (e) {
      print('Error in skipBackward(): $e');
    }
  }

  /// Seek to position (called from JavaScript via callback)
  static void seek(int seconds) {
    print('[Dart] seek($seconds) called');
    try {
      AudioService.instance.seek(Duration(seconds: seconds));
    } catch (e) {
      print('Error in seek(): $e');
    }
  }
}
