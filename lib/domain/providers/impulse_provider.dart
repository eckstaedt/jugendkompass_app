import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugendkompass_app/data/models/impulse_model.dart';
import 'package:jugendkompass_app/data/repositories/impulse_repository.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';

final impulseRepositoryProvider = Provider<ImpulseRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ImpulseRepository(supabase);
});

final dailyImpulsesProvider = FutureProvider<List<ImpulseModel>>((ref) async {
  final repository = ref.watch(impulseRepositoryProvider);
  return await repository.getDailyImpulses(limit: 10);
});

final impulseDetailProvider = FutureProvider.family<ImpulseModel?, String>((
  ref,
  impulseId,
) async {
  final repository = ref.watch(impulseRepositoryProvider);
  return await repository.getImpulseById(impulseId);
});
