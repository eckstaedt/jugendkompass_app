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

    // Set action handlers
    mediaSession.setActionHandler('play', () => {
      if (this.callbacks.play) this.callbacks.play();
      this.updatePlaybackState(true);
    });

    mediaSession.setActionHandler('pause', () => {
      if (this.callbacks.pause) this.callbacks.pause();
      this.updatePlaybackState(false);
    });

    mediaSession.setActionHandler('previoustrack', () => {
      if (this.callbacks.skipPrevious) this.callbacks.skipPrevious();
    });

    mediaSession.setActionHandler('nexttrack', () => {
      if (this.callbacks.skipNext) this.callbacks.skipNext();
    });

    mediaSession.setActionHandler('seekto', (details) => {
      if (this.callbacks.seek) {
        this.callbacks.seek(details.seekTime);
      }
      this.position = details.seekTime;
      this.updateMediaSession();
    });

    mediaSession.setActionHandler('seekbackward', (details) => {
      const skipTime = details.seekOffset || 5;
      this.position = Math.max(0, this.position - skipTime);
      if (this.callbacks.seek) this.callbacks.seek(this.position);
      this.updateMediaSession();
    });

    mediaSession.setActionHandler('seekforward', (details) => {
      const skipTime = details.seekOffset || 5;
      this.position = Math.min(this.duration, this.position + skipTime);
      if (this.callbacks.seek) this.callbacks.seek(this.position);
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
