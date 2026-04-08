import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'dart:async';

class AudioService {
  static AudioService? _instance;
  late final AudioPlayer _player;

  // Queue management
  List<AudioModel> _queue = [];
  int _currentIndex = 0;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  /// Called whenever the service auto-advances to the next track (e.g. on
  /// completion).  Riverpod providers hook into this so they stay in sync.
  void Function(int newIndex, AudioModel? newAudio)? onTrackChanged;

  AudioService._() {
    _player = AudioPlayer();
    _setupPlayerStateListener();
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

  // Setup listener for auto-play next
  void _setupPlayerStateListener() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (hasNext) {
          _autoPlayNext();
        }
      }
    });
  }

  /// Internal auto-advance that also notifies Riverpod via the callback.
  Future<void> _autoPlayNext() async {
    if (!hasNext) return;
    _currentIndex++;
    await playAudio(
      _queue[_currentIndex].audioUrl,
      audio: _queue[_currentIndex],
    );
    onTrackChanged?.call(_currentIndex, currentAudio);
  }

  /// Build a [MediaItem] tag from an [AudioModel] for lock screen display.
  /// The [id] MUST be set to the audio URL so that just_audio_background
  /// can correctly map it to the underlying platform audio source.
  MediaItem _mediaItem(AudioModel audio) {
    return MediaItem(
      id: audio.audioUrl,
      title: audio.title ?? audio.post?.title ?? 'Audio',
      artist: audio.artist ?? 'Jugendkompass',
      artUri: audio.imageUrl != null ? Uri.tryParse(audio.imageUrl!) : null,
      duration: audio.duration,
    );
  }

  Future<void> playAudio(String url, {AudioModel? audio}) async {
    try {
      // Always provide a MediaItem tag – just_audio_background requires it
      // for iOS/Android lock screen controls (artwork, title, play/pause).
      final tag = audio != null
          ? _mediaItem(audio)
          : MediaItem(
              id: url,
              title: 'Audio',
              artist: 'Jugendkompass',
            );
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(url), tag: tag),
      );
      await _player.play();
    } catch (e) {
      throw Exception('Fehler beim Abspielen: $e');
    }
  }

  // Queue management methods
  Future<void> setQueue(List<AudioModel> audios, {int startIndex = 0}) async {
    if (audios.isEmpty) return;
    if (startIndex < 0 || startIndex >= audios.length) {
      startIndex = 0;
    }

    _queue = List.from(audios);
    _currentIndex = startIndex;

    // Play the audio at the start index, passing the model so the lock
    // screen gets the correct title / artwork.
    await playAudio(
      _queue[_currentIndex].audioUrl,
      audio: _queue[_currentIndex],
    );
  }

  void addToQueue(AudioModel audio) {
    _queue.add(audio);
  }

  Future<void> playNext() async {
    if (!hasNext) return;
    _currentIndex++;
    await playAudio(
      _queue[_currentIndex].audioUrl,
      audio: _queue[_currentIndex],
    );
  }

  Future<void> playPrevious() async {
    if (!hasPrevious) return;
    _currentIndex--;
    await playAudio(
      _queue[_currentIndex].audioUrl,
      audio: _queue[_currentIndex],
    );
  }

  Future<void> skipToQueueIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await playAudio(
      _queue[_currentIndex].audioUrl,
      audio: _queue[_currentIndex],
    );
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex && _currentIndex >= _queue.length) {
      _currentIndex = _queue.length - 1;
    }
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = 0;
  }

  AudioModel? get currentAudio {
    if (_queue.isEmpty || _currentIndex < 0 || _currentIndex >= _queue.length) {
      return null;
    }
    return _queue[_currentIndex];
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

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

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  bool get isPlaying => _player.playing;
  Duration? get duration => _player.duration;
  Duration get position => _player.position;

  void dispose() {
    _playerStateSubscription?.cancel();
    _player.dispose();
  }
}
