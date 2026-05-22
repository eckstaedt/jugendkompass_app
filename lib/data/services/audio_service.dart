import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AudioService {
  static AudioService? _instance;
  late final AudioPlayer _player;

  // Queue management
  List<AudioModel> _queue = [];
  int _currentIndex = 0;

  // The current ConcatenatingAudioSource (null when single-source mode)
  ConcatenatingAudioSource? _playlist;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;

  /// Called whenever the service auto-advances to the next track.
  void Function(int newIndex, AudioModel? newAudio)? onTrackChanged;

  /// Called when audio playback completes and there's no next track.
  void Function()? onPlaybackComplete;

  AudioService._() {
    _player = AudioPlayer();
    _setupPlayerStateListener();
    _setupCurrentIndexListener();
  }

  static AudioService get instance {
    _instance ??= AudioService._();
    return _instance!;
  }

  AudioPlayer get player => _player;

  // Queue getters
  List<AudioModel> get queue => List.unmodifiable(_queue);
  int get currentQueueIndex => _currentIndex;
  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  // Listen for track changes triggered by lock screen skip buttons or auto-advance
  void _setupCurrentIndexListener() {
    _currentIndexSubscription = _player.currentIndexStream.listen((index) {
      debugPrint('[AudioService] Current index changed: $index (previous: $_currentIndex, queue length: ${_queue.length})');
      if (index != null && index != _currentIndex && index < _queue.length) {
        _currentIndex = index;
        debugPrint('[AudioService] Track changed to index $_currentIndex: ${currentAudio?.title}');
        onTrackChanged?.call(_currentIndex, currentAudio);
      }
    });
  }

  // Listen for playlist completion
  void _setupPlayerStateListener() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      debugPrint('[AudioService] Player state changed: ${state.processingState}, current index: $_currentIndex, queue length: ${_queue.length}');

      // Only call onPlaybackComplete when truly at the end of the queue
      if (state.processingState == ProcessingState.completed) {
        // For ConcatenatingAudioSource, check the player's current index
        final playerIndex = _player.currentIndex;
        debugPrint('[AudioService] Playback completed. Player index: $playerIndex, Queue index: $_currentIndex, Queue length: ${_queue.length}');

        // If we're at the last track (or player index indicates end)
        if (playerIndex == null || playerIndex >= _queue.length - 1 || _currentIndex >= _queue.length - 1) {
          debugPrint('[AudioService] Reached end of queue, calling onPlaybackComplete');
          onPlaybackComplete?.call();
        }
      }
    });
  }

  /// Build a [MediaItem] tag from an [AudioModel] for lock screen display.
  MediaItem _mediaItem(AudioModel audio) {
    return MediaItem(
      id: audio.audioUrl,
      title: audio.title ?? audio.post?.title ?? 'Audio',
      artist: audio.artist ?? 'Jugendkompass',
      artUri: audio.imageUrl != null ? Uri.tryParse(audio.imageUrl!) : null,
      duration: audio.duration,
    );
  }

  /// Play a single audio (no queue).
  Future<void> playAudio(String url, {AudioModel? audio}) async {
    try {
      final tag = audio != null
          ? _mediaItem(audio)
          : MediaItem(id: url, title: 'Audio', artist: 'Jugendkompass');
      _playlist = null;
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(url), tag: tag),
      );
      await _player.play();
    } catch (e) {
      throw Exception('Fehler beim Abspielen: $e');
    }
  }

  /// Set a full queue and start playback.
  /// Uses [ConcatenatingAudioSource] so lock screen skip buttons work natively.
  Future<void> setQueue(List<AudioModel> audios, {int startIndex = 0}) async {
    if (audios.isEmpty) return;
    if (startIndex < 0 || startIndex >= audios.length) startIndex = 0;

    _queue = List.from(audios);
    _currentIndex = startIndex;

    debugPrint('[AudioService] Setting queue: ${audios.length} items, starting at index $startIndex');

    // Always use ConcatenatingAudioSource for queue functionality
    // This enables auto-advance to next track and lock screen controls
    final sources = audios.map((a) {
      return AudioSource.uri(Uri.parse(a.audioUrl), tag: _mediaItem(a));
    }).toList();

    _playlist = ConcatenatingAudioSource(children: sources);

    try {
      await _player.setAudioSource(_playlist!, initialIndex: startIndex);
      await _player.play();
      debugPrint('[AudioService] Queue loaded and playing');
    } catch (e) {
      debugPrint('[AudioService] Error loading queue: $e');
      throw Exception('Fehler beim Laden der Wiedergabeliste: $e');
    }
  }

  /// Add an audio to the end of the current playlist.
  Future<void> addToQueue(AudioModel audio) async {
    debugPrint('[AudioService] Adding to queue: ${audio.title}, current queue size: ${_queue.length}');
    _queue.add(audio);
    if (_playlist != null) {
      await _playlist!.add(
        AudioSource.uri(Uri.parse(audio.audioUrl), tag: _mediaItem(audio)),
      );
      debugPrint('[AudioService] Added to playlist, new queue size: ${_queue.length}');
    } else {
      debugPrint('[AudioService] WARNING: No playlist active, audio added to queue but not to player');
    }
  }

  Future<void> playNext() async {
    if (!hasNext) return;
    if (_playlist != null) {
      await _player.seekToNext();
    } else {
      _currentIndex++;
      await playAudio(_queue[_currentIndex].audioUrl, audio: _queue[_currentIndex]);
    }
  }

  Future<void> playPrevious() async {
    if (!hasPrevious) return;
    if (_playlist != null) {
      await _player.seekToPrevious();
    } else {
      _currentIndex--;
      await playAudio(_queue[_currentIndex].audioUrl, audio: _queue[_currentIndex]);
    }
  }

  Future<void> skipToQueueIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    if (_playlist != null) {
      await _player.seek(Duration.zero, index: index);
    } else {
      await playAudio(_queue[_currentIndex].audioUrl, audio: _queue[_currentIndex]);
    }
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    _playlist?.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex && _currentIndex >= _queue.length) {
      _currentIndex = _queue.length - 1;
    }
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = 0;
    _playlist = null;
  }

  AudioModel? get currentAudio {
    if (_queue.isEmpty || _currentIndex < 0 || _currentIndex >= _queue.length) {
      return null;
    }
    return _queue[_currentIndex];
  }

  Future<void> pause() async => _player.pause();
  Future<void> resume() async => _player.play();
  Future<void> stop() async => _player.stop();

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipForward(int seconds) async {
    final currentPosition = _player.position;
    final newPosition = currentPosition + Duration(seconds: seconds);
    final maxPosition = _player.duration ?? currentPosition;
    await _player.seek(newPosition <= maxPosition ? newPosition : maxPosition);
  }

  Future<void> skipBackward(int seconds) async {
    final currentPosition = _player.position;
    final newPosition = currentPosition - Duration(seconds: seconds);
    await _player.seek(newPosition.isNegative ? Duration.zero : newPosition);
  }

  Future<void> setSpeed(double speed) async => _player.setSpeed(speed);

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  bool get isPlaying => _player.playing;
  Duration? get duration => _player.duration;
  Duration get position => _player.position;

  void dispose() {
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _player.dispose();
  }
}
