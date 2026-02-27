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

// Queue management providers
final audioQueueProvider = StateProvider<List<AudioModel>>((ref) => []);

final currentQueueIndexProvider = StateProvider<int>((ref) => 0);

final nextAudioProvider = Provider<AudioModel?>((ref) {
  final queue = ref.watch(audioQueueProvider);
  final index = ref.watch(currentQueueIndexProvider);
  if (index < queue.length - 1) {
    return queue[index + 1];
  }
  return null;
});

final previousAudioProvider = Provider<AudioModel?>((ref) {
  final queue = ref.watch(audioQueueProvider);
  final index = ref.watch(currentQueueIndexProvider);
  if (index > 0) {
    return queue[index - 1];
  }
  return null;
});

final hasNextAudioProvider = Provider<bool>((ref) {
  final queue = ref.watch(audioQueueProvider);
  final index = ref.watch(currentQueueIndexProvider);
  return index < queue.length - 1;
});

final hasPreviousAudioProvider = Provider<bool>((ref) {
  final index = ref.watch(currentQueueIndexProvider);
  return index > 0;
});

// Recommended audios provider
final recommendedAudiosProvider = FutureProvider<List<AudioModel>>((ref) async {
  final audioRepository = ref.watch(audioRepositoryProvider);
  final currentAudio = ref.watch(currentAudioProvider);

  if (currentAudio == null) {
    return [];
  }

  try {
    return await audioRepository.getRecommendedAudios(
      categoryId: currentAudio.post?.categoryId,
      excludeAudioId: currentAudio.id,
      limit: 10,
    );
  } catch (e) {
    // Return empty list on error
    return [];
  }
});
