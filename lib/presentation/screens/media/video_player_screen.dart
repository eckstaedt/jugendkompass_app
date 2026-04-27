import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:jugendkompass_app/data/models/collection_item_model.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/utils/html_utils.dart';
import 'package:jugendkompass_app/domain/providers/collection_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoUrl;
  final String title;
  final String? imageUrl;
  final String? description;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    this.imageUrl,
    this.description,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _isInitialized = false;
  String? _error;
  bool _isYouTube = false;
  String? _youtubeVideoId;

  @override
  void initState() {
    super.initState();
    // Pause any currently playing audio when entering video player
    final audioService = ref.read(audioServiceProvider);
    if (audioService.isPlaying) {
      audioService.pause();
    }
    _checkVideoType();
  }

  void _checkVideoType() {
    final url = widget.videoUrl;
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      _isYouTube = true;
      _youtubeVideoId = _extractYouTubeVideoId(url);
      if (_youtubeVideoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: _youtubeVideoId!,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
          ),
        );
        setState(() {
          _isInitialized = true;
        });
      } else {
        setState(() {
          _error = AppTranslations.t('invalid_youtube_url');
        });
      }
    } else {
      _initializePlayer();
    }
  }

  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController.initialize();

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          bufferedColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        controlsSafeAreaMinimum: const EdgeInsets.only(
          bottom: 20,
          left: 16,
          right: 16,
        ),
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${AppTranslations.t('error_loading_video')}: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInCollection = ref.watch(collectionProvider).any(
          (item) =>
              item.id == widget.videoUrl && item.type == CollectionItemType.video,
        );

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        actions: [
          if (widget.description != null && widget.description!.trim().isNotEmpty)
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.info_outline, size: 24),
                  onPressed: () {
                    final RenderBox button = context.findRenderObject() as RenderBox;
                    final RenderBox overlay = Navigator.of(context)
                        .overlay!
                        .context
                        .findRenderObject() as RenderBox;
                    final position = RelativeRect.fromRect(
                      Rect.fromPoints(
                        button.localToGlobal(Offset.zero, ancestor: overlay),
                        button.localToGlobal(
                          button.size.bottomRight(Offset.zero),
                          ancestor: overlay,
                        ),
                      ),
                      Offset.zero & overlay.size,
                    );
                    showMenu(
                      context: context,
                      position: position,
                      color: Colors.grey.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(maxWidth: 300),
                      items: [
                        PopupMenuItem(
                          enabled: false,
                          child: Text(
                            HtmlUtils.stripHtml(widget.description!),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final item = CollectionItem(
                    id: widget.videoUrl,
                    title: widget.title,
                    description: widget.description,
                    imageUrl: widget.imageUrl,
                    type: CollectionItemType.video,
                    savedAt: DateTime.now(),
                  );
                  ref.read(collectionProvider.notifier).toggleCollection(item);
                },
                child: Icon(
                  isInCollection ? Icons.bookmark : Icons.bookmark_outline,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.redAccent.shade100,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _isInitialized = false;
                        });
                        _checkVideoType();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(AppTranslations.t('try_again')),
                    ),
                  ],
                ),
              )
            : _isInitialized
                ? _isYouTube && _youtubeController != null
                    ? YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: true,
                      )
                    : _chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : const CircularProgressIndicator(color: Colors.white)
                : const CircularProgressIndicator(color: Colors.white),
      ),
      ),
    );
  }
}
