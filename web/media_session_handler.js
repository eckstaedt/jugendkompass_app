// Media Session Handler for Web
// Provides Lock Screen / Media Controls for Web Apps

// Global Dart callback holder - will be set by Dart code
window.dartAudioCallbacks = {
  play: null,
  pause: null,
  skipForward: null,
  skipBackward: null,
  seek: null,
};

class MediaSessionHandler {
  constructor() {
    this.currentAudio = null;
    this.isPlaying = false;
    this.position = 0;
    this.duration = 0;
    this.audioElement = null;
    this.callbacks = {
      play: null,
      pause: null,
      skipNext: null,
      skipPrevious: null,
      seek: null,
    };
  }

  // Initialize Media Session API
  init() {
    if (!('mediaSession' in navigator)) {
      console.warn('MediaSession API is not supported in this browser');
      return false;
    }

    this.setupMediaSessionHandlers();
    return true;
  }

  // Set up handlers for media control actions
  setupMediaSessionHandlers() {
    if (!('mediaSession' in navigator)) return;

    const mediaSession = navigator.mediaSession;

    // Set action handlers
    mediaSession.setActionHandler('play', () => {
      console.log('MediaSession: play');
      if (this.callbacks.play) this.callbacks.play();
      // Call Dart function if available
      if (window.dartAudioCallbacks.play && typeof window.dartAudioCallbacks.play === 'function') {
        console.log('Calling dartAudioCallbacks.play');
        window.dartAudioCallbacks.play();
      } else if (typeof window.dartAudioPlay === 'function') {
        console.log('Calling window.dartAudioPlay');
        window.dartAudioPlay();
      } else {
        console.warn('No Dart play function available');
      }
      this.updatePlaybackState(true);
    });

    mediaSession.setActionHandler('pause', () => {
      console.log('MediaSession: pause');
      if (this.callbacks.pause) this.callbacks.pause();
      // Call Dart function if available
      if (window.dartAudioCallbacks.pause && typeof window.dartAudioCallbacks.pause === 'function') {
        console.log('Calling dartAudioCallbacks.pause');
        window.dartAudioCallbacks.pause();
      } else if (typeof window.dartAudioPause === 'function') {
        console.log('Calling window.dartAudioPause');
        window.dartAudioPause();
      } else {
        console.warn('No Dart pause function available');
      }
      this.updatePlaybackState(false);
    });

    mediaSession.setActionHandler('previoustrack', () => {
      console.log('MediaSession: previoustrack (skip backward)');
      if (this.callbacks.skipPrevious) this.callbacks.skipPrevious();
      // Call Dart function if available
      if (window.dartAudioCallbacks.skipBackward && typeof window.dartAudioCallbacks.skipBackward === 'function') {
        console.log('Calling dartAudioCallbacks.skipBackward(10)');
        window.dartAudioCallbacks.skipBackward(10);
      } else if (typeof window.dartAudioSkipBackward === 'function') {
        console.log('Calling window.dartAudioSkipBackward(10)');
        window.dartAudioSkipBackward(10);
      }
    });

    mediaSession.setActionHandler('nexttrack', () => {
      console.log('MediaSession: nexttrack (skip forward)');
      if (this.callbacks.skipNext) this.callbacks.skipNext();
      // Call Dart function if available
      if (window.dartAudioCallbacks.skipForward && typeof window.dartAudioCallbacks.skipForward === 'function') {
        console.log('Calling dartAudioCallbacks.skipForward(10)');
        window.dartAudioCallbacks.skipForward(10);
      } else if (typeof window.dartAudioSkipForward === 'function') {
        console.log('Calling window.dartAudioSkipForward(10)');
        window.dartAudioSkipForward(10);
      }
    });

    mediaSession.setActionHandler('seekto', (details) => {
      console.log('MediaSession: seekto', details.seekTime);
      if (this.callbacks.seek) {
        this.callbacks.seek(details.seekTime);
      }
      // Call Dart function if available
      if (window.dartAudioCallbacks.seek && typeof window.dartAudioCallbacks.seek === 'function') {
        console.log('Calling dartAudioCallbacks.seek(' + Math.floor(details.seekTime) + ')');
        window.dartAudioCallbacks.seek(Math.floor(details.seekTime));
      } else if (typeof window.dartAudioSeek === 'function') {
        console.log('Calling window.dartAudioSeek(' + Math.floor(details.seekTime) + ')');
        window.dartAudioSeek(Math.floor(details.seekTime));
      }
      this.position = details.seekTime;
      this.updateMediaSession();
    });

    mediaSession.setActionHandler('seekbackward', (details) => {
      console.log('MediaSession: seekbackward');
      const skipTime = 10; // 10 seconds
      this.position = Math.max(0, this.position - skipTime);
      if (this.callbacks.seek) this.callbacks.seek(this.position);
      // Call Dart function if available
      if (window.dartAudioCallbacks.skipBackward && typeof window.dartAudioCallbacks.skipBackward === 'function') {
        console.log('Calling dartAudioCallbacks.skipBackward(10)');
        window.dartAudioCallbacks.skipBackward(10);
      } else if (typeof window.dartAudioSkipBackward === 'function') {
        console.log('Calling window.dartAudioSkipBackward(10)');
        window.dartAudioSkipBackward(10);
      }
      this.updateMediaSession();
    });

    mediaSession.setActionHandler('seekforward', (details) => {
      console.log('MediaSession: seekforward');
      const skipTime = 10; // 10 seconds
      this.position = Math.min(this.duration, this.position + skipTime);
      if (this.callbacks.seek) this.callbacks.seek(this.position);
      // Call Dart function if available
      if (window.dartAudioCallbacks.skipForward && typeof window.dartAudioCallbacks.skipForward === 'function') {
        console.log('Calling dartAudioCallbacks.skipForward(10)');
        window.dartAudioCallbacks.skipForward(10);
      } else if (typeof window.dartAudioSkipForward === 'function') {
        console.log('Calling window.dartAudioSkipForward(10)');
        window.dartAudioSkipForward(10);
      }
      this.updateMediaSession();
    });
  }

  // Update media metadata for lock screen / media controls
  updateMediaSession(audio = null, position = null, duration = null, isPlaying = null) {
    if (!('mediaSession' in navigator)) return;

    if (audio) {
      this.currentAudio = audio;
    }
    if (position !== null) {
      this.position = position;
    }
    if (duration !== null) {
      this.duration = duration;
    }
    if (isPlaying !== null) {
      this.isPlaying = isPlaying;
    }

    if (!this.currentAudio) {
      navigator.mediaSession.metadata = null;
      return;
    }

    // Create metadata for lock screen
    const metadata = new MediaMetadata({
      title: this.currentAudio.title || 'Podcast',
      artist: this.currentAudio.artist || this.currentAudio.post?.title || 'Jugendkompass',
      album: 'Jugendkompass',
      artwork: this.currentAudio.imageUrl
        ? [
            {
              src: this.currentAudio.imageUrl,
              sizes: '256x256',
              type: 'image/jpeg',
            },
            {
              src: this.currentAudio.imageUrl,
              sizes: '512x512',
              type: 'image/jpeg',
            },
          ]
        : [],
    });

    navigator.mediaSession.metadata = metadata;
        window.dartAudioPause();
      }
      this.updatePlaybackState(false);
    });

    mediaSession.setActionHandler('previoustrack', () => {
      if (this.callbacks.skipPrevious) this.callbacks.skipPrevious();
      // Call Dart function if available
      if (typeof window.dartAudioSkipBackward === 'function') {
        window.dartAudioSkipBackward(10);
      }
    });

    mediaSession.setActionHandler('nexttrack', () => {
      if (this.callbacks.skipNext) this.callbacks.skipNext();
      // Call Dart function if available
      if (typeof window.dartAudioSkipForward === 'function') {
        window.dartAudioSkipForward(10);
      }
    });

    mediaSession.setActionHandler('seekto', (details) => {
      if (this.callbacks.seek) {
        this.callbacks.seek(details.seekTime);
      }
      // Call Dart function if available
      if (typeof window.dartAudioSeek === 'function') {
        window.dartAudioSeek(Math.floor(details.seekTime));
      }
      this.position = details.seekTime;
      this.updateMediaSession();
    });

    mediaSession.setActionHandler('seekbackward', (details) => {
      const skipTime = 10; // 10 seconds
      this.position = Math.max(0, this.position - skipTime);
      if (this.callbacks.seek) this.callbacks.seek(this.position);
      // Call Dart function if available
      if (typeof window.dartAudioSkipBackward === 'function') {
        window.dartAudioSkipBackward(10);
      }
      this.updateMediaSession();
    });

    mediaSession.setActionHandler('seekforward', (details) => {
      const skipTime = 10; // 10 seconds
      this.position = Math.min(this.duration, this.position + skipTime);
      if (this.callbacks.seek) this.callbacks.seek(this.position);
      // Call Dart function if available
      if (typeof window.dartAudioSkipForward === 'function') {
        window.dartAudioSkipForward(10);
      }
      this.updateMediaSession();
    });
  }

  // Update media metadata for lock screen / media controls
  updateMediaSession(audio = null, position = null, duration = null, isPlaying = null) {
    if (!('mediaSession' in navigator)) return;

    if (audio) {
      this.currentAudio = audio;
    }
    if (position !== null) {
      this.position = position;
    }
    if (duration !== null) {
      this.duration = duration;
    }
    if (isPlaying !== null) {
      this.isPlaying = isPlaying;
    }

    if (!this.currentAudio) {
      navigator.mediaSession.metadata = null;
      return;
    }

    // Create metadata for lock screen
    const metadata = new MediaMetadata({
      title: this.currentAudio.title || 'Podcast',
      artist: this.currentAudio.artist || this.currentAudio.post?.title || 'Jugendkompass',
      album: 'Jugendkompass',
      artwork: this.currentAudio.imageUrl
        ? [
            {
              src: this.currentAudio.imageUrl,
              sizes: '256x256',
              type: 'image/jpeg',
            },
            {
              src: this.currentAudio.imageUrl,
              sizes: '512x512',
              type: 'image/jpeg',
            },
          ]
        : [],
    });

    navigator.mediaSession.metadata = metadata;

    // Update playback state
    navigator.mediaSession.playbackState = this.isPlaying ? 'playing' : 'paused';

    // Update position state (for seek bar)
    if ('setPositionState' in navigator.mediaSession) {
      navigator.mediaSession.setPositionState({
        duration: this.duration,
        playbackRate: 1,
        position: this.position,
      });
    }
  }

  // Update only playback state (playing/paused)
  updatePlaybackState(isPlaying) {
    if (!('mediaSession' in navigator)) return;
    
    this.isPlaying = isPlaying;
    navigator.mediaSession.playbackState = isPlaying ? 'playing' : 'paused';
  }

  // Register callbacks for media control actions
  onPlay(callback) {
    this.callbacks.play = callback;
  }

  onPause(callback) {
    this.callbacks.pause = callback;
  }

  onSkipNext(callback) {
    this.callbacks.skipNext = callback;
  }

  onSkipPrevious(callback) {
    this.callbacks.skipPrevious = callback;
  }

  onSeek(callback) {
    this.callbacks.seek = callback;
  }

  // Clear media session (e.g., when stopping)
  clear() {
    if (!('mediaSession' in navigator)) return;
    navigator.mediaSession.metadata = null;
    navigator.mediaSession.playbackState = 'none';
  }
}

// Global instance
const mediaSessionHandler = new MediaSessionHandler();

// Initialize on load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    mediaSessionHandler.init();
  });
} else {
  mediaSessionHandler.init();
}
