import 'package:flutter/foundation.dart' show kIsWeb;

class ImageUrlHelper {
  /// Fix CORS issues for web by using a proxy service
  /// For mobile/desktop, return the original URL
  static String getCorsProxyUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    // Only apply proxy for web platform
    if (kIsWeb && imageUrl.contains('wp.jugendkompass.com')) {
      // Option 1: Use a public CORS proxy (for development only)
      // return 'https://corsproxy.io/?${Uri.encodeComponent(imageUrl)}';

      // Option 2: Use allOrigins proxy
      // return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(imageUrl)}';

      // For now, return original URL
      // The server should be configured to allow CORS
      return imageUrl;
    }

    return imageUrl;
  }

  /// Alternative: Download and re-upload to Supabase storage
  /// This completely avoids CORS issues but requires backend work
  static Future<String?> migrateToSupabaseStorage(
    String externalUrl,
    String supabaseStorageBucket,
  ) async {
    // TODO: Implement if needed
    // 1. Download image from external URL
    // 2. Upload to Supabase storage
    // 3. Return Supabase URL
    return null;
  }
}
