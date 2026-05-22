import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/domain/providers/recommendation_provider.dart';
import 'package:jugendkompass_app/domain/providers/translation_provider.dart';
import 'package:jugendkompass_app/domain/providers/read_history_provider.dart';
import 'package:jugendkompass_app/data/models/read_history_item_model.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/utils/html_utils.dart';
import 'package:jugendkompass_app/core/utils/snackbar_utils.dart';
import 'package:jugendkompass_app/presentation/navigation/mini_player_overlay.dart' show currentAudioNotifier;
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';
import 'package:jugendkompass_app/presentation/screens/home/widgets/poll_content_tile.dart';

class RecommendedContentTile extends ConsumerStatefulWidget {
  final RecommendedItem item;
  final VoidCallback? onTap;

  const RecommendedContentTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  ConsumerState<RecommendedContentTile> createState() => _RecommendedContentTileState();
}

class _RecommendedContentTileState extends ConsumerState<RecommendedContentTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  Future<void> _playAudio(BuildContext context) async {
    final item = widget.item;
    if (!item.hasAudio || item.post?.audioId == null) return;

    try {
      final audioRepository = ref.read(audioRepositoryProvider);
      final audio = await audioRepository.getAudioById(item.post!.audioId!);

      if (audio == null) {
        if (context.mounted) {
          SnackBarUtils.showError(context, AppTranslations.t('audio_not_found'));
        }
        return;
      }

      // Update providers immediately so the mini player bar appears instantly
      ref.read(audioQueueProvider.notifier).state = [audio];
      ref.read(currentQueueIndexProvider.notifier).state = 0;
      ref.read(currentAudioProvider.notifier).state = audio;
      currentAudioNotifier.value = audio;

      // Mark audio as listened
      ref.read(readHistoryProvider.notifier).markAsRead(
        audio.id,
        ReadContentType.audio,
        title: audio.title ?? audio.post?.title,
        imageUrl: audio.imageUrl,
      );

      // Start playback (setQueue calls playAudio internally)
      final audioService = ref.read(audioServiceProvider);
      await audioService.setQueue([audio], startIndex: 0);
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, '${AppTranslations.t('error_playing')}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    // If this is a poll, render PollContentTile instead
    if (item.isPoll && item.poll != null) {
      return PollContentTile(poll: item.poll!);
    }

    final theme = Theme.of(context);

    // Translate item title to the selected app language
    final titleAsync = ref.watch(translateTextProvider(item.title));
    final displayTitle = HtmlUtils.stripHtml(titleAsync.whenOrNull(data: (t) => t) ?? item.title);

    // Determine content type for read history check
    final ReadContentType contentType;
    final String readId;
    if (item.isVideo) {
      contentType = ReadContentType.video;
      readId = item.videoUrl ?? item.id; // Videos tracked by URL
    } else if (item.isMessage) {
      contentType = ReadContentType.message;
      readId = item.id;
    } else {
      // Posts (including those with audio) are tracked as posts
      contentType = ReadContentType.post;
      readId = item.id;
    }

    // Check if content is read
    final isRead = ref.watch(isContentReadProvider((id: readId, type: contentType)));

    // Show NEW badge if: not read AND created within last 2 days
    final isNew = !isRead && DateTime.now().difference(item.createdAt).inDays < 2;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Opacity(
        opacity: isRead ? 0.6 : 1.0,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: DesignTokens.glassBlurSigma,
                    sigmaY: DesignTokens.glassBlurSigma),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: DesignTokens.getGlassBackground(Theme.of(context).brightness, 0.26),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
                    border: DesignTokens.cardBorder(Theme.of(context).brightness),
                    boxShadow: [DesignTokens.shadowGlass],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.spacingSmall),
                    child: Row(
                      children: [
                        // Thumbnail with play overlay
                        GestureDetector(
                          onTap: item.hasAudio ? () => _playAudio(context) : null,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: DesignTokens.getAppBackground(Theme.of(context).brightness),
                              borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                              boxShadow: [DesignTokens.shadowSubtle],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusButtons),
                              child: Stack(
                                children: [
                                  item.imageUrl != null && item.imageUrl!.isNotEmpty
                                      ? CorsNetworkImage(imageUrl: item.imageUrl!, width: 80, height: 80, fit: BoxFit.cover)
                                      : SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: Icon(
                                            item.isVideo ? Icons.play_circle_outline : item.isMessage ? Icons.message_outlined : Icons.article_outlined,
                                            size: 32,
                                            color: DesignTokens.primaryRed,
                                          ),
                                        ),
                                  if (item.hasAudio)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.35),
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                displayTitle,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  final isDark = Theme.of(context).brightness == Brightness.dark;
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (isNew)
                                        BadgeWidget(
                                          label: context.tr('new_badge'),
                                          backgroundColor: isDark ? DesignTokens.primaryRed : null,
                                          textColor: isDark ? Colors.white : null,
                                        ),
                                      BadgeWidget(
                                        label: item.isVideo
                                          ? context.tr('video_badge')
                                          : item.isKurznachricht
                                            ? context.tr('short_message_badge')
                                            : context.tr('article_badge'),
                                        backgroundColor: isDark ? DesignTokens.primaryRed : null,
                                        textColor: isDark ? Colors.white : null,
                                      ),
                                      if (item.hasAudio)
                                        BadgeWidget(
                                          label: context.tr('audio_badge'),
                                          backgroundColor: DesignTokens.successGreen.withOpacity(0.12),
                                          textColor: DesignTokens.successGreen,
                                          icon: Icons.headphones,
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
