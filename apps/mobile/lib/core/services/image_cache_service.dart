import 'package:flutter/material.dart';

/// Optimized image caching configuration
/// Maximizes in-memory cache, reduces disk cache to prevent storage bloat
class ImageCacheConfig {
  static void configure() {
    // Configure in-memory image cache
    imageCache.maximumSize = 100; // max 100 images
    imageCache.maximumSizeBytes = 256 * 1024 * 1024; // 256 MB

    // CachedNetworkImage automatically handles disk caching
    // Default max age: 30 days (good for content that doesn't change often)
  }
}
