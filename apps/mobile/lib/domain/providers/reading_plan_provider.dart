import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/reading_plan_model.dart';
import '../../data/repositories/reading_plan_repository.dart';
import 'supabase_provider.dart';

/// Reading plan repository provider
final readingPlanRepositoryProvider = Provider<ReadingPlanRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ReadingPlanRepository(supabase);
});

/// Current reading plan provider
final currentReadingPlanProvider =
    StateNotifierProvider<ReadingPlanNotifier, AsyncValue<ReadingPlanModel?>>(
  (ref) => ReadingPlanNotifier(ref),
);

class ReadingPlanNotifier extends StateNotifier<AsyncValue<ReadingPlanModel?>> {
  final Ref ref;

  ReadingPlanNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadReadingPlan();
  }

  Future<void> _loadReadingPlan() async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(readingPlanRepositoryProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;

      var plan = await repository.getUserReadingPlan(userId);

      // Create new plan if none exists
      plan ??= await repository.createReadingPlan(userId);

      state = AsyncValue.data(plan);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleDayCompletion(int dayNumber) async {
    final currentPlan = state.value;
    if (currentPlan == null) return;

    final day = currentPlan.days.firstWhere(
      (d) => d.dayNumber == dayNumber,
      orElse: () => ReadingDay(dayNumber: dayNumber, isCompleted: false),
    );

    final repository = ref.read(readingPlanRepositoryProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    await repository.updateDayCompletion(
      userId,
      currentPlan.currentWeek,
      dayNumber,
      !day.isCompleted,
    );

    // Refresh the plan
    await _loadReadingPlan();
  }

  Future<void> createPlan() async {
    try {
      final repository = ref.read(readingPlanRepositoryProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;

      final plan = await repository.createReadingPlan(userId);
      state = AsyncValue.data(plan);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadReadingPlan();
  }
}
