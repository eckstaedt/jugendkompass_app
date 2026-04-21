import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:jugendkompass_app/data/repositories/verse_repository.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';
import 'package:jugendkompass_app/core/services/home_widget_service.dart';

final verseRepositoryProvider = Provider<VerseRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return VerseRepository(supabase);
});

final dailyVerseProvider = FutureProvider<VerseModel?>((ref) async {
  final repository = ref.watch(verseRepositoryProvider);
  final language = ref.watch(languageProvider).locale.languageCode;

  final verse = await repository.getTodaysVerseLocalized(language);

  // Sync verse to iOS Home Screen Widget
  if (verse != null) {
    await HomeWidgetService.updateVerseWidget(verse);
  }

  return verse;
});

final recentVersesProvider = FutureProvider<List<VerseModel>>((ref) async {
  final repository = ref.watch(verseRepositoryProvider);
  final language = ref.watch(languageProvider).locale.languageCode;

  return await repository.getRecentVersesLocalized(language);
});
