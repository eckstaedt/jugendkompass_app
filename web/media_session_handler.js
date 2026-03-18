// Media Session Handler for Web
// Provides Lock Screen / Media Controls for Web Apps

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
    const self = this;

    // Set action handlers
    mediaSession.setActionHandler('play', () => {
      console.log('[MediaSession] play');
      if (self.callbacks.play) self.callbacks.play();
      // Call Dart function via dartAudioAPI
      if (window.dartAudioAPI && typeof window.dartAudioAPI.play === 'function') {
        console.log('[MediaSession->Dart] Calling dartAudioAPI.play()');
        try {
          window.dartAudioAPI.play();
        } catch (e) {
          console.error('[MediaSession->Dart] Error calling play:', e);
        }
      } else {
        console.warn('[MediaSession->Dart] dartAudioAPI.play not available');
      }
      self.updatePlaybackState(true);
    });

    mediaSession.setActionHandler('pause', () => {
      console.log('[MediaSession] pause');
      if (self.callbacks.pause) self.callbacks.pause();
      // Call Dart function via dartAudioAPI
      if (window.dartAudioAPI && typeof window.dartAudioAPI.pause === 'function') {
        console.log('[MediaSession->Dart] Calling dartAudioAPI.pause()');
        try {
          window.dartAudioAPI.pause();
        } catch (e) {
          console.error('[MediaSession->Dart] Error calling pause:', e);
        }
      } else {
        console.warn('[MediaSession->Dart] dartAudioAPI.pause not available');
      }
      self.updatePlaybackState(false);
    });

    mediaSession.setActionHandler('previoustrack', () => {
      console.log('[MediaSession] previoustrack (skip -10s)');
      if (self.callbacks.skipPrevious) self.callbacks.skipPrevious();
      // Call Dart function via dartAudioAPI
      if (window.dartAudioAPI && typeof window.dartAudioAPI.skipBackward === 'function') {
        console.log('[MediaSession->Dart] Calling dartAudioAPI.skipBackward(10)');
        try {
          window.dartAudioAPI.skipBackward(10);
        } catch (e) {
          console.error('[MediaSession->Dart] Error calling skipBackward:', e);
        }
      } else {
        console.warn('[MediaSession->Dart] dartAudioAPI.skipBackward not available');
      }
    });

    mediaSession.setActionHandler('nexttrack', () => {
      console.log('[MediaSession] nexttrack (skip +10s)');
      if (self.callbacks.skipNext) self.callbacks.skipNext();
      // Call Dart function via dartAudioAPI
      if (window.dartAudioAPI && typeof window.dartAudioAPI.skipForward === 'function') {
        console.log('[MediaSession->Dart] Calling dartAudioAPI.skipForward(10)');
        try {
          window.dartAudioAPI.skipForward(10);
        } catch (e) {
          console.error('[MediaSession->Dart] Error calling skipForward:', e);
        }
      } else {
        console.warn('[MediaSession->Dart] dartAudioAPI.skipForward not available');
      }
    });

    mediaSession.setActionHandler('seekto', (details) => {
      console.log('[MediaSession] seekto', details.seekTime);
      if (self.callbacks.seek) {
        self.callbacks.seek(details.seekTime);
      }
      // Call Dart function via dartAudioAPI
      if (window.dartAudioAPI && typeof window.dartAudioAPI.seek === 'function') {
        console.log('[MediaSession->Dart] Calling dartAudioAPI.seek(' + Math.floor(details.seekTime) + ')');
        try {
          window.dartAudioAPI.seek(Math.floor(details.seekTime));
        } catch (e) {
          console.error('[MediaSession->Dart] Error calling seek:', e);
        }
      } else {
        console.warn('[MediaSession->Dart] dartAudioAPI.seek not available');
      }
      self.position = details.seekTime;
      self.updateMediaSession();
    });

    mediaSession.setActionHandler('seekbackward', (details) => {
      console.log('[MediaSession] seekbackward');
      const skipTime = 10; // 10 seconds
      self.position = Math.max(0, self.position - skipTime);
      if (self.callbacks.seek) self.callbacks.seek(self.position);
      // Call Dart function via dartAudioAPI
      if (window.dartAudioAPI && typeof window.dartAudioAPI.skipBackward === 'function') {
        console.log('[MediaSession->Dart] Calling dartAudioAPI.skipBackward(10)');
        try {
          window.dartAudioAPI.skipBackward(10);
        } catch (e) {
          console.error('[MediaSession->Dart] Error calling skipBackward:', e);
        }
      }
      self.updateMediaSession();
    });

    mediaSession.setActionHandler('seekforward', (details) => {
      console.log('[MediaSession] seekforward');
      const skipTime = 10; // 10 seconds
      self.position = Math.min(self.duration, self.position + skipTime);
      if (self.callbacks.seek) self.callbacks.seek(self.position);
      // Call Dart function via dartAudioAPI
      if (window.dartAudioAPI && typeof window.dartAudioAPI.skipForward === 'function') {
        console.log('[MediaSession->Dart] Calling dartAudioAPI.skipForward(10)');
        try {
          window.dartAudioAPI.skipForward(10);
        } catch (e) {
          console.error('[MediaSession->Dart] Error calling skipForward:', e);
        }
      }
      self.updateMediaSession();
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
