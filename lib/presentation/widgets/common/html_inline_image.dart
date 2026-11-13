import 'package:jugendkompass_app/presentation/widgets/common/skeleton_loading.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';

/// Renders `<img>` tags inside HTML content (e.g. short messages) as
/// block images in their original aspect ratio.
///
/// The image is shown at its natural size and only scaled down (never up,
/// never stretched or cropped) when it is wider than the text column.
/// Supports regular URLs and legacy `data:image/...;base64,` sources.
TagExtension htmlInlineImageExtension() {
  return TagExtension(
    tagsToExtend: {'img'},
    builder: (extensionContext) {
      final src = extensionContext.attributes['src']?.trim() ?? '';
      if (src.isEmpty) return const SizedBox.shrink();
      return HtmlInlineImage(
        src: src,
        alt: extensionContext.attributes['alt'],
      );
    },
  );
}

class HtmlInlineImage extends StatelessWidget {
  final String src;
  final String? alt;

  const HtmlInlineImage({super.key, required this.src, this.alt});

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final placeholder = Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DesignTokens.getCardBackground(brightness),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: const AreaSkeleton(),
    );
    final error = Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DesignTokens.getCardBackground(brightness),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: const Icon(Icons.broken_image, size: 40),
    );

    Widget image;
    if (src.startsWith('data:image')) {
      final bytes = _decodeDataUri(src);
      image = bytes == null
          ? error
          : Image.memory(
              bytes,
              fit: BoxFit.contain,
              semanticLabel: alt,
              errorBuilder: (_, _, _) => error,
            );
    } else {
      // No width/height: the image keeps its intrinsic size and aspect ratio
      // and is only scaled down to fit the available width.
      image = CorsNetworkImage(
        imageUrl: src,
        fit: BoxFit.contain,
        placeholder: placeholder,
        errorWidget: error,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: image,
          ),
        ),
      ),
    );
  }

  static Uint8List? _decodeDataUri(String uri) {
    final comma = uri.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(uri.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }
}
