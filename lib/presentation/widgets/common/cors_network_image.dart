import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// A network image widget that handles CORS issues on web
/// For web: uses a CORS proxy for problematic domains
/// For mobile: uses CachedNetworkImage for better performance
class CorsNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CorsNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  /// Get CORS-safe URL for web
  String _getCorsProxyUrl(String url) {
    if (!kIsWeb) return url;

    // If the URL is from wp.jugendkompass.com, use a CORS proxy
    if (url.contains('wp.jugendkompass.com')) {
      // Use corsproxy.io as CORS proxy
      return 'https://corsproxy.io/?${Uri.encodeComponent(imageUrl)}';
    }

    return url;
  }

  @override
  Widget build(BuildContext context) {
    final processedUrl = _getCorsProxyUrl(imageUrl);

    // For web, use Image.network with proxied URL
    if (kIsWeb) {
      return Image.network(
        processedUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image loading error for $imageUrl: $error');
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image, size: 48),
              );
        },
      );
    }

    // For mobile/desktop, use CachedNetworkImage for better performance
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      placeholder: (context, url) =>
          placeholder ??
          Center(
            child: CircularProgressIndicator(),
          ),
      errorWidget: (context, url, error) {
        debugPrint('Image loading error for $url: $error');
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image, size: 48),
            );
      },
    );
  }
}
