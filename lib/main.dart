import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jugendkompass_app/app.dart';
import 'package:jugendkompass_app/core/config/env_config.dart';
import 'package:jugendkompass_app/core/services/image_cache_service.dart';
import 'package:jugendkompass_app/data/services/supabase_service.dart';
import 'package:jugendkompass_app/data/services/favorites_service.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for German locale
  await initializeDateFormatting('de_DE', null);

  // Load environment variables
  await EnvConfig.load();

  // Initialize image caching
  ImageCacheConfig.configure();

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize User Preferences Service
  await UserPreferencesService.instance.init();

  // Initialize Favorites Service
  await FavoritesService.instance.initialize();

  runApp(const ProviderScope(child: App()));
}
