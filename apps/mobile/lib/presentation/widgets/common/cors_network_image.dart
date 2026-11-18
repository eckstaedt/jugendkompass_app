import 'package:jugendkompass_app/presentation/widgets/common/skeleton_loading.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jugendkompass_app/data/services/image_localizer.dart';

/// A network image widget that works across all platforms
/// Uses CachedNetworkImage for mobile and Image.network for web
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

  @override
  Widget build(BuildContext context) {
    // Cover images with AI-translated text replace the original per language.
    return ValueListenableBuilder<Map<String, String>>(
      valueListenable: ImageLocalizer.instance.map,
      builder: (context, map, _) => _build(context, map[imageUrl] ?? imageUrl),
    );
  }

  Widget _build(BuildContext context, String imageUrl) {
    // For web, use Image.network
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              const AreaSkeleton();
        },
        errorBuilder: (context, error, stackTrace) {
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
          const AreaSkeleton(),
      errorWidget: (context, url, error) {
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
