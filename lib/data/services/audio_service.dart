import 'package:just_audio/just_audio.dart';

class AudioService {
  static AudioService? _instance;
  late final AudioPlayer _player;

  AudioService._() {
    _player = AudioPlayer();
  }

  static AudioService get instance {
    _instance ??= AudioService._();
    return _instance!;
  }

  AudioPlayer get player => _player;

  Future<void> playAudio(String url) async {
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      throw Exception('Fehler beim Abspielen: $e');
    }
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
    _player.dispose();
  }
}
