import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/domain/providers/post_provider.dart';
import 'package:jugendkompass_app/domain/providers/verse_provider.dart';
import 'package:jugendkompass_app/domain/providers/video_provider.dart';
import 'package:jugendkompass_app/domain/providers/message_provider.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/presentation/screens/post/post_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/media/video_player_screen.dart';
import 'package:jugendkompass_app/presentation/screens/content/content_detail_screen.dart';
import 'package:jugendkompass_app/presentation/screens/message/message_detail_screen.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart'
    show kVideoPlayerRouteName;
import 'package:google_fonts/google_fonts.dart';

/// Service for handling deep links from push notifications.
///
/// Maps content types and IDs to appropriate screen navigation.
class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._internal();
  DeepLinkService._internal();

  /// Navigate to content based on notification data payload.
  ///
  /// Expected data structure (format 1):
  /// ```
  /// {
  ///   "contentType": "post" | "video" | "verse" | "impulse" | "message",
  ///   "contentId": "uuid-string"
  /// }
  /// ```
  ///
  /// Alternative format (format 2):
  /// ```
  /// {
  ///   "type": "post" | "video" | "verse" | "impulse" | "message",
  ///   "content_id": "uuid-string",
  ///   "entity_id": "uuid-string"  // optional
  /// }
  /// ```
  Future<void> handleNotificationTap({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> data,
  }) async {
    debugPrint('[DeepLink] handleNotificationTap called with data: $data');

    // Support both formats
    String? contentType = data['contentType'] as String? ?? data['type'] as String?;
    String? contentId = data['contentId'] as String? ?? data['content_id'] as String? ?? data['entity_id'] as String?;

    debugPrint('[DeepLink] contentType: $contentType, contentId: $contentId');

    if (contentType == null || contentId == null) {
      debugPrint('[DeepLink] Missing contentType or contentId in data: $data');
      return;
    }

    debugPrint('[DeepLink] Navigating to $contentType with id: $contentId');

    try {
      switch (contentType.toLowerCase()) {
        case 'post':
          await _navigateToPost(context, ref, contentId);
          break;
        case 'video':
          await _navigateToVideo(context, ref, contentId);
          break;
        case 'verse':
          await _navigateToVerse(context, ref, contentId);
          break;
        case 'message':
          await _navigateToMessage(context, ref, contentId);
          break;
        case 'impulse':
        case 'poll':
          // Generic content screen handles these types
          _navigateToContent(context, contentId);
          break;
        default:
          debugPrint('[DeepLink] Unknown contentType: $contentType');
          // Fallback to generic content screen
          _navigateToContent(context, contentId);
      }
    } catch (e) {
      debugPrint('[DeepLink] Error navigating to content: $e');
    }
  }

  /// Navigate to a post detail screen.
  Future<void> _navigateToPost(
    BuildContext context,
    WidgetRef ref,
    String postId,
  ) async {
    // Fetch post data first
    final postAsync = ref.read(postByIdProvider(postId).future);
    final post = await postAsync;

    if (post == null) {
      debugPrint('[DeepLink] Post not found: $postId');
      return;
    }

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: post),
      ),
    );
  }

  /// Navigate to a video player screen.
  Future<void> _navigateToVideo(
    BuildContext context,
    WidgetRef ref,
    String videoId,
  ) async {
    // Fetch video data first
    final videoAsync = ref.read(videoByIdProvider(videoId).future);
    final video = await videoAsync;

    if (video == null) {
      debugPrint('[DeepLink] Video not found: $videoId');
      return;
    }

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: kVideoPlayerRouteName),
        builder: (context) => VideoPlayerScreen(
          videoUrl: video.videoUrl,
          title: video.displayTitle,
          description: video.description,
          imageUrl: video.imageUrl,
        ),
      ),
    );
  }

  /// Navigate to verse of the day detail.
  /// Since verses are displayed on home screen, we can show a dialog or navigate to home.
  Future<void> _navigateToVerse(
    BuildContext context,
    WidgetRef ref,
    String verseId,
  ) async {
    // Fetch verse data
    final verseAsync = ref.read(verseByIdProvider(verseId).future);
    final verse = await verseAsync;

    if (verse == null) {
      debugPrint('[DeepLink] Verse not found: $verseId');
      return;
    }

    if (!context.mounted) return;

    // Show verse in a dialog since there's no dedicated verse detail screen
    showDialog(
      context: context,
      builder: (context) => _VerseDialog(verse: verse),
    );
  }

  /// Navigate to a message detail screen.
  Future<void> _navigateToMessage(
    BuildContext context,
    WidgetRef ref,
    String contentId,
  ) async {
    debugPrint('[DeepLink] _navigateToMessage called with contentId: $contentId');

    // Fetch message data by content_id (not by message id)
    final messageAsync = ref.read(messageByContentIdProvider(contentId).future);
    final message = await messageAsync;

    if (message == null) {
      debugPrint('[DeepLink] Message not found for contentId: $contentId');
      return;
    }

    if (!context.mounted) return;

    debugPrint('[DeepLink] Pushing MessageDetailScreen');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MessageDetailScreen(message: message),
      ),
    );
  }

  /// Navigate to generic content detail screen.
  void _navigateToContent(BuildContext context, String contentId) {
    debugPrint('[DeepLink] _navigateToContent called with contentId: $contentId');

    if (!context.mounted) {
      debugPrint('[DeepLink] Context not mounted, cannot navigate');
      return;
    }

    debugPrint('[DeepLink] Pushing ContentDetailScreen');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(contentId: contentId),
      ),
    );
    debugPrint('[DeepLink] ContentDetailScreen push completed');
  }
}

/// Dialog to display verse of the day when tapped from notification.
class _VerseDialog extends ConsumerWidget {
  final VerseModel verse;

  const _VerseDialog({required this.verse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final translate = ref.watch(stringTranslatorProvider);

    // The verse is already localized from verseByIdProvider
    // which uses verse_repository.dart's getVerseById that should use localized data
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translate('Tagesvers'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              verse.verse,
              style: GoogleFonts.merriweather(
                textStyle: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '— ${verse.reference}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(translate('Schließen')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
