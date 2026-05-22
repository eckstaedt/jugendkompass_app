import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jugendkompass_app/data/models/collection_item_model.dart';
import 'package:jugendkompass_app/data/models/read_history_item_model.dart';
import 'package:jugendkompass_app/core/localization/app_translations.dart';
import 'package:jugendkompass_app/core/utils/html_utils.dart';
import 'package:jugendkompass_app/domain/providers/collection_provider.dart';
import 'package:jugendkompass_app/domain/providers/audio_player_provider.dart';
import 'package:jugendkompass_app/domain/providers/read_history_provider.dart';

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
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _isInitialized = false;
  String? _error;
  bool _isYouTube = false;
  String? _youtubeVideoId;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    // Pause any currently playing audio when entering video player
    final audioService = ref.read(audioServiceProvider);
    if (audioService.isPlaying) {
      audioService.pause();
    }
    _checkVideoType();

    // Mark video as watched
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readHistoryProvider.notifier).markAsRead(
        widget.videoUrl,
        ReadContentType.video,
        title: HtmlUtils.stripHtml(widget.title),
        imageUrl: widget.imageUrl,
      );
    });
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

  /// Check if error is a codec/decoder error that might benefit from retry
  bool _isCodecError(String error) {
    final lowerError = error.toLowerCase();
    return lowerError.contains('mediacodec') ||
        lowerError.contains('codec') ||
        lowerError.contains('decoder') ||
        lowerError.contains('no_exceeds_capabilities') ||
        lowerError.contains('exceeds capabilities') ||
        lowerError.contains('decoderinitialization') ||
        lowerError.contains('failed to allocate buffers') ||
        lowerError.contains('videorenderer');
  }

  /// Parse platform-specific video errors and provide user-friendly messages
  String _handleVideoError(String rawError) {
    final lowerError = rawError.toLowerCase();

    // Codec errors - enhanced detection for MediaCodec issues
    if (_isCodecError(rawError)) {
      return AppTranslations.t('video_codec_error');
    }

    // Network/loading errors
    if (lowerError.contains('source error') ||
        lowerError.contains('cannot connect') ||
        lowerError.contains('network')) {
      return AppTranslations.t('video_network_error');
    }

    // Format not supported
    if (lowerError.contains('format') ||
        lowerError.contains('not supported') ||
        lowerError.contains('nosupport')) {
      return AppTranslations.t('video_format_error');
    }

    // Generic fallback
    return '${AppTranslations.t('error_loading_video')}: ${rawError.split('\n').first}';
  }

  /// Dispose current video player resources to free up decoder
  Future<void> _disposeVideoPlayer() async {
    _chewieController?.dispose();
    _chewieController = null;
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;
  }

  Future<void> _initializePlayer({bool isRetry = false}) async {
    try {
      // Dispose any existing player first to free up decoder resources
      await _disposeVideoPlayer();

      // On retry, add a delay to allow system to release decoder resources
      if (isRetry) {
        debugPrint('[VideoPlayer] Retry attempt $_retryCount - waiting for decoder resources...');
        await Future.delayed(Duration(milliseconds: 500 * _retryCount));
      }

      debugPrint('[VideoPlayer] Initializing: ${widget.videoUrl} (attempt ${_retryCount + 1})');

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      await _videoPlayerController!.initialize();

      debugPrint('[VideoPlayer] Initialized successfully. '
          'Codec: ${_videoPlayerController!.value.isInitialized ? "supported" : "unknown"}, '
          'Aspect ratio: ${_videoPlayerController!.value.aspectRatio}');

      if (!mounted) return;

      // Listen for codec/playback errors after initialization
      _videoPlayerController!.addListener(_onVideoPlayerError);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        errorBuilder: (context, errorMessage) {
          // Custom error UI for playback errors
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.white70),
                const SizedBox(height: 16),
                Text(
                  _handleVideoError(errorMessage),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
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
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('[VideoPlayer] Initialization error (attempt ${_retryCount + 1}): $e');

      // Auto-retry for codec errors
      if (_isCodecError(e.toString()) && _retryCount < _maxRetries) {
        _retryCount++;
        debugPrint('[VideoPlayer] Codec error detected, retrying (${_retryCount}/$_maxRetries)...');
        await _initializePlayer(isRetry: true);
        return;
      }

      if (mounted) {
        setState(() {
          _error = _handleVideoError(e.toString());
        });
      }
    }
  }

  void _onVideoPlayerError() {
    if (_videoPlayerController?.value.hasError ?? false) {
      final error = _videoPlayerController!.value.errorDescription ?? 'Unknown error';
      debugPrint('[VideoPlayer] Runtime error: $error');

      // Try to recover from codec errors during playback
      if (_isCodecError(error) && _retryCount < _maxRetries && mounted) {
        _retryCount++;
        debugPrint('[VideoPlayer] Runtime codec error, attempting recovery (${_retryCount}/$_maxRetries)...');
        setState(() {
          _isInitialized = false;
        });
        _initializePlayer(isRetry: true);
        return;
      }

      if (mounted) {
        setState(() {
          _error = _handleVideoError(error);
        });
      }
    }
  }

  /// Open video in external browser/player app
  Future<void> _openInExternalPlayer() async {
    final uri = Uri.parse(widget.videoUrl);
    try {
      // Try to launch in external application (video player)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        // Fallback to browser if external app launch fails
        await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      }
    } catch (e) {
      debugPrint('[VideoPlayer] Failed to open external player: $e');
      // Last resort: try any available method
      if (mounted) {
        await launchUrl(uri);
      }
    }
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Remove listener before disposing
    _videoPlayerController?.removeListener(_onVideoPlayerError);
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Add troubleshooting tip for codec errors
                    if (_error!.contains('codec') || _error!.contains('Codec') ||
                        _error!.contains('Gerät') || _error!.contains('device'))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          AppTranslations.t('video_codec_help'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Retry button
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _isInitialized = false;
                          _retryCount = 0; // Reset retry count for manual retry
                        });
                        _checkVideoType();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(AppTranslations.t('try_again')),
                    ),
                    const SizedBox(height: 12),
                    // Open in external player button
                    OutlinedButton.icon(
                      onPressed: _openInExternalPlayer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 20),
                      label: Text(AppTranslations.t('open_external_player')),
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
