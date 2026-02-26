import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/content_model.dart';
import 'package:jugendkompass_app/data/models/audio_model.dart';
import 'package:jugendkompass_app/domain/providers/content_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';

// Model to unify content and audio for recommendations
class RecommendedItem {
  final String id;
  final String title;
  final String contentType; // 'post', 'audio', 'video', etc.
  final String? imageUrl;
  final String? audioId;
  final AudioModel? audioModel; // If this is an audio item

  RecommendedItem({
    required this.id,
    required this.title,
    required this.contentType,
    this.imageUrl,
    this.audioId,
    this.audioModel,
  });

  factory RecommendedItem.fromContent(ContentModel content) {
    return RecommendedItem(
      id: content.id,
      title: content.displayTitle,
      contentType: content.contentType,
      imageUrl: content.imageUrl,
      audioId: content.audioId,
    );
  }

  factory RecommendedItem.fromAudio(AudioModel audio) {
    return RecommendedItem(
      id: audio.id,
      title: audio.title ?? 'Audio',
      contentType: 'audio',
      imageUrl: audio.thumbnailUrl,
      audioId: audio.id,
      audioModel: audio,
    );
  }

  bool get isAudio => contentType.toLowerCase() == 'audio' || audioId != null;
  bool get isVideo => contentType.toLowerCase() == 'video';
  bool get isPost => contentType.toLowerCase() == 'post';
}

final recommendedContentProvider = FutureProvider<List<RecommendedItem>>((ref) async {
  try {
    // Fetch random posts (excluding impulses and verses)
    final contentRepository = ref.watch(contentRepositoryProvider);
    final posts = await contentRepository.getContentList(
      contentType: 'post',
      limit: 5,
    );

    // Fetch random audios
    final audioRepository = ref.watch(audioRepositoryProvider);
    final audios = await audioRepository.getAudioList(limit: 5);

    // Convert to RecommendedItems
    final postItems = posts.map((post) => RecommendedItem.fromContent(post)).toList();
    final audioItems = audios.map((audio) => RecommendedItem.fromAudio(audio)).toList();

    // Combine and shuffle
    final combined = [...postItems, ...audioItems];
    combined.shuffle();

    // Return first 10 items
    return combined.take(10).toList();
  } catch (e) {
    throw Exception('Fehler beim Laden der Empfehlungen: $e');
  }
});
