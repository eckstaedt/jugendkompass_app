import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jugendkompass_app/data/services/supabase_service.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.instance.client;
});
