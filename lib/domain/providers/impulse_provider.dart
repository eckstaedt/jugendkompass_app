import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/impulse_model.dart';
import 'package:jugendkompass_app/data/repositories/impulse_repository.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';
import 'package:jugendkompass_app/domain/providers/language_provider.dart';

final impulseRepositoryProvider = Provider<ImpulseRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ImpulseRepository(supabase);
});

final dailyImpulsesProvider = FutureProvider<List<ImpulseModel>>((ref) async {
  final repository = ref.watch(impulseRepositoryProvider);
  final language = ref.watch(languageProvider).locale.languageCode;

  return await repository.getImpulsesLocalized(language, limit: 1000);
});

final impulseDetailProvider = FutureProvider.family<ImpulseModel?, String>((
  ref,
  impulseId,
) async {
  final repository = ref.watch(impulseRepositoryProvider);
  final language = ref.watch(languageProvider).locale.languageCode;

  return await repository.getImpulseByIdLocalized(impulseId, language);
});

/// Single impulse provider by content_id (FK to the polymorphic `content`
/// table). Used for deep linking from push notifications.
final impulseByContentIdProvider = FutureProvider.family<ImpulseModel?, String>(
  (ref, contentId) async {
    final repository = ref.watch(impulseRepositoryProvider);
    return await repository.getImpulseByContentId(contentId);
  },
);
