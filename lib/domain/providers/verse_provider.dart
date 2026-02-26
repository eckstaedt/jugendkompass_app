import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/data/repositories/verse_repository.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';

final verseRepositoryProvider = Provider<VerseRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return VerseRepository(supabase);
});

final dailyVerseProvider = FutureProvider<VerseModel?>((ref) async {
  final repository = ref.watch(verseRepositoryProvider);
  return await repository.getTodaysVerse();
});

final recentVersesProvider = FutureProvider<List<VerseModel>>((ref) async {
  final repository = ref.watch(verseRepositoryProvider);
  return await repository.getRecentVerses();
});
