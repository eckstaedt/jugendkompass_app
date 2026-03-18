// Dart Audio API Bridge
// This provides global access to Dart audio functions

// This object will be populated by Dart code after the app initializes
window.dartAudioAPI = {
  initialized: false,
  
  // Set up the Dart functions
  initialize: function(dartFunctions) {
    console.log('Initializing Dart Audio API');
    
    if (dartFunctions) {
      // Store Dart function references
      window.dartAudioCallbacks.play = dartFunctions.play;
      window.dartAudioCallbacks.pause = dartFunctions.pause;
      window.dartAudioCallbacks.skipForward = dartFunctions.skipForward;
      window.dartAudioCallbacks.skipBackward = dartFunctions.skipBackward;
      window.dartAudioCallbacks.seek = dartFunctions.seek;
      
      this.initialized = true;
      console.log('Dart Audio API initialized successfully');
    } else {
      console.warn('No Dart functions provided to initialize');
    }
  },
  
  // Call Dart play function
  play: function() {
    console.log('dartAudioAPI.play()');
    if (window.dartAudioCallbacks.play && typeof window.dartAudioCallbacks.play === 'function') {
      window.dartAudioCallbacks.play();
    } else {
      console.warn('Dart play function not available');
    }
  },
  
  // Call Dart pause function
  pause: function() {
    console.log('dartAudioAPI.pause()');
    if (window.dartAudioCallbacks.pause && typeof window.dartAudioCallbacks.pause === 'function') {
      window.dartAudioCallbacks.pause();
    } else {
      console.warn('Dart pause function not available');
    }
  },
  
  // Call Dart skip forward function
  skipForward: function(seconds) {
    console.log('dartAudioAPI.skipForward(' + seconds + ')');
    if (window.dartAudioCallbacks.skipForward && typeof window.dartAudioCallbacks.skipForward === 'function') {
      window.dartAudioCallbacks.skipForward(seconds);
    } else {
      console.warn('Dart skipForward function not available');
    }
  },
  
  // Call Dart skip backward function
  skipBackward: function(seconds) {
    console.log('dartAudioAPI.skipBackward(' + seconds + ')');
    if (window.dartAudioCallbacks.skipBackward && typeof window.dartAudioCallbacks.skipBackward === 'function') {
      window.dartAudioCallbacks.skipBackward(seconds);
    } else {
      console.warn('Dart skipBackward function not available');
    }
  },
  
  // Call Dart seek function
  seek: function(seconds) {
    console.log('dartAudioAPI.seek(' + seconds + ')');
    if (window.dartAudioCallbacks.seek && typeof window.dartAudioCallbacks.seek === 'function') {
      window.dartAudioCallbacks.seek(seconds);
    } else {
      console.warn('Dart seek function not available');
    }
  }
};

// Also expose as window.dart* for backward compatibility
window.dartAudioPlay = function() {
  window.dartAudioAPI.play();
};

window.dartAudioPause = function() {
  window.dartAudioAPI.pause();
};

window.dartAudioSkipForward = function(seconds) {
  window.dartAudioAPI.skipForward(seconds);
};

window.dartAudioSkipBackward = function(seconds) {
  window.dartAudioAPI.skipBackward(seconds);
};

window.dartAudioSeek = function(seconds) {
  window.dartAudioAPI.seek(seconds);
};
