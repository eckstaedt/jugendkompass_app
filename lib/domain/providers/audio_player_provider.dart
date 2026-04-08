import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/data/repositories/audio_repository.dart';
import 'package:jugendkompass_app/data/services/audio_service.dart';
import 'package:jugendkompass_app/data/services/media_notification_service.dart';
import 'package:jugendkompass_app/data/services/web_media_session_handler.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';

final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AudioRepository(supabase);
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService.instance;
  // Keep Riverpod in sync when the service auto-advances to the next track.
  service.onTrackChanged = (newIndex, newAudio) {
    ref.read(currentQueueIndexProvider.notifier).state = newIndex;
    ref.read(currentAudioProvider.notifier).state = newAudio;
  };
  return service;
});

final mediaNotificationServiceProvider = Provider<MediaNotificationService>((ref) {
  return MediaNotificationService();
});

final webMediaSessionHandlerProvider = Provider<WebMediaSessionHandler>((ref) {
  return WebMediaSessionHandler();
});

final audioListProvider = FutureProvider<List<AudioModel>>((ref) async {
  final repository = ref.watch(audioRepositoryProvider);
  return await repository.getAudioList();
});

final currentAudioProvider = StateProvider<AudioModel?>((ref) => null);

final isPlayingProvider = Provider<bool>((ref) {
  final playerState = ref.watch(audioPlayerStateProvider);
  return playerState.when(
    data: (state) => state.playing,
    loading: () => false,
    error: (_, _) => false,
  );
});

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

/// The extra bottom offset (in logical pixels) that the persistent mini player
/// bar should sit above.  Set to the navbar height on [BottomNavScreen] and
/// reset to 0 on pushed routes.
final miniPlayerBottomOffsetProvider = StateProvider<double>((ref) => 0);

/// Whether the main app navbar should be shown.
/// Defaults to false; set to true by BottomNavScreen when active.
final navBarVisibleProvider = StateProvider<bool>((ref) => false);

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

// Media notification update provider
final mediaNotificationProvider = StreamProvider<void>((ref) async* {
  final currentAudio = ref.watch(currentAudioProvider);
  final isPlaying = ref.watch(isPlayingProvider);
  final position = ref.watch(audioPositionProvider);
  final duration = ref.watch(audioDurationProvider);
  final mediaService = ref.watch(mediaNotificationServiceProvider);
  final webHandler = ref.watch(webMediaSessionHandlerProvider);

  // Update notification whenever audio, playing state, position, or duration changes
  position.whenData((pos) {
    duration.whenData((dur) {
      if (currentAudio != null && dur != null) {
        // Update native notification
        mediaService.showPlaybackNotification(
          audio: currentAudio,
          isPlaying: isPlaying,
          position: pos,
          duration: dur,
        );
        // Update web media session
        webHandler.updateMediaSession(
          audio: currentAudio,
          isPlaying: isPlaying,
          position: pos,
          duration: dur,
        );
      } else if (currentAudio == null) {
        mediaService.hidePlaybackNotification();
        webHandler.clear();
      }
    });
  });

  yield* Stream.empty();
});

