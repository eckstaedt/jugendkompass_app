import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/data/repositories/audio_repository.dart';
import 'package:jugendkompass_app/data/services/audio_service.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';

final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AudioRepository(supabase);
});

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService.instance;
});

final audioListProvider = FutureProvider<List<AudioModel>>((ref) async {
  final repository = ref.watch(audioRepositoryProvider);
  return await repository.getAudioList();
});

final currentAudioProvider = StateProvider<AudioModel?>((ref) => null);

final isPlayingProvider = StateProvider<bool>((ref) => false);

final audioPositionProvider = StreamProvider<Duration>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.positionStream;
});

final audioDurationProvider = StreamProvider<Duration?>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.durationStream;
});

final audioPlayerStateProvider = StreamProvider<PlayerState>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.playerStateStream;
});
