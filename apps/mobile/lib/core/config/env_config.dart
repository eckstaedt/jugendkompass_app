import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class EnvConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: 'dotenv');
    } catch (e) {
      // On web, if .env file is not found, we need to handle it gracefully
      if (kIsWeb) {
        debugPrint('Warning: .env file not found on web. Please ensure environment variables are set.');
        debugPrint('Error: $e');
        // For web, you can use environment variables from the build process
        // or hardcode them (not recommended for production)
      } else {
        // On mobile, this is a critical error
        rethrow;
      }
    }
  }

  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}
