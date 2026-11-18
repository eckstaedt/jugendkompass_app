import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Memory optimization service for clearing unused resources
class MemoryOptimizationService {
  static void optimizeOnLowMemory() {
    // Clear image cache when memory is low
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  static void clearRiverPodCache(WidgetRef ref, List<FutureProvider> providers) {
    for (final provider in providers) {
      ref.invalidate(provider);
    }
  }

  /// Pre-cache essential images on app startup
  static Future<void> preCacheImages(List<String> imageUrls, BuildContext context) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(
          NetworkImage(url),
          context,
        );
      } catch (e) {
        // Ignore errors in precaching
      }
    }
  }
}
